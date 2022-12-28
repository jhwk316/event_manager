
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]  
end

def clean_phone_number(phone)
  case 
  when phone.include?("-")
    phone.gsub("-", "")
  when phone.include?(" ")
    phone.gsub(" ", "")
  when phone.length < 10
    phone.replace("Invalid Number")
  when phone.length > 10 && phone[0] == "1"
    phone[1..10]
  when phone.length > 10
    phone.replace("Invalid Number")
  else
    phone
  end
end

hours = []
def most_frequent_time(arr)
  arr.max_by {|h| arr.count(h)}
end

day_of_week = []
def most_frequent_day(arr)
  arr.max_by {|d| arr.count(d)}
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

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
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

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  phone = clean_phone_number(row[:homephone])
   
  zipcode = clean_zipcode(row[:zipcode])
  
  reg_date = Time.strptime(row[:regdate], "%D %H")
  hours.push(reg_date.hour)
  
  reg_day = Date.strptime(row[:regdate], "%D")
  day_of_week.push(reg_day.strftime("%A"))

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  

 save_thank_you_letter(id,form_letter)
 
 
end
puts "The most frequent time people register is at #{most_frequent_time(hours)}:00"
puts "The most frequent day people register is on #{most_frequent_day(day_of_week)}s"

