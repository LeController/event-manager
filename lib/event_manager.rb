require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.delete('^0-9')
  if phone_number.length < 10 || phone_number.length > 11
    "INVALID NUMBER"
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1,phone_number.length]
  else
    phone_number
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours_of_registration = []
days_of_registration = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  reg_datetime = Time.strptime(row[:regdate], '%m/%d/%y %k:%M')
  
  hours_of_registration.push(reg_datetime.hour)

  days = {0 => "Sunday",
    1 => "Monday", 
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday"}
    
  days_of_registration.push(days[reg_datetime.wday])

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)  
end

# Creates hash where key is the hour and value is the number of users registered on that hour
registration_hours = hours_of_registration.inject({}) do |hsh, hour|
  hsh[hour] ||= 0
  hsh[hour] += 1
  hsh
end
# Creates hash where key is the day and value is the number of users registered on that day
registration_days = days_of_registration.inject({}) do |hsh, day|
  hsh[day] ||= 0
  hsh[day] += 1
  hsh
end

p registration_hours
p registration_days