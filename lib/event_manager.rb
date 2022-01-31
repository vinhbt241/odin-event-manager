require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcodes(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone)
  phone = phone.gsub(/\D/, "")

  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == 1
    phone[1..-1]
  else
    "Bad Number"
  end
end

def find_peak(record)
  max_val = 0
  record.each_value do |val|
    max_val = val if max_val < val
  end

  hash = record.filter do |key, val|
    val == max_val
  end
  
  peak = []
  hash.each_key do |k|
    peak.push(k.to_i)
  end

  peak
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_record = Hash.new(0)
week_record = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcodes(row[:zipcode])

  phone_number = clean_phone_numbers(row[:homephone])

  reg_date = Time.strptime(row[:regdate], "%y/%d/%m %k:%M")

  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)
  
  save_thank_you_letter(id, form_letter)

  hour_record[reg_date.hour.to_s] += 1

  week_record[reg_date.wday.to_s] += 1
end

peak_hours = find_peak(hour_record)
p peak_hours

peak_days = find_peak(week_record)
peak_days = peak_days.map do |day|
  Date::DAYNAMES[day]
end
p peak_days



