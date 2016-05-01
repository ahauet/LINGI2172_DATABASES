#!/usr/bin/env ruby
# Usage: sparkling_water.rb [-u username] [-p password] [-d database_name]

require_relative 'DBmanager' # including the DBmanager will execute all the code that it contains. So we will already have a connection to the database, a full operational database schema and it will be populated.
puts "__________________________________________________________\n\n"

# A simple helper function to display a bill in a nicer format
def puts_formated_bill(res)
  puts "You looked at the bill."
  puts "The total to pay is : #{res[:total]}"
  puts "Details below :\n---------------------"
  res[:details].each { |detail_line|
    puts "#{detail_line[:name]} => #{detail_line[:qty]}"
    puts '---------------------'
  }
end

token = acquire_table(1)
puts "You scanned the codebar and your token is #{token}"

my_order = [{:drink_id=>6, :qty=>1}] # the argument to pass to the function must be an array of Hashes
order = order_drinks(token, my_order)
puts "You ordered a sparkling water. The order id is #{order}"

ticket = issue_ticket(token)
puts_formated_bill(ticket)

order = order_drinks(token, my_order)
puts "You ordered a sparkling water. The order id is #{order}"

ticket = issue_ticket(token)
puts_formated_bill(ticket)

pay_table(token, 10.0)
puts "You have paid and you leave...it's sunny outside"
