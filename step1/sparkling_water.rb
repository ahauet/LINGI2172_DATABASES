#!/usr/bin/env ruby
# Usage: sparkling_water.rb [-u username] [-p password]

require 'pg'
require 'optparse'

# Parse args
options = {:username => "postgres"}
OptionParser.new do |opts|
  opts.banner = "Usage: sparkling_water.rb [-u username] [-p password]"
  opts.on('-u', '--optional username', 'Username to connect to database') { |v| options[:username] = v }
  opts.on('-p', '--require password', 'Password to connect to database') { |v| options[:password] = v }
end.parse!

# Some variables
acquire_table_request = "select acquire_table(1)"
token = nil

# First, establish the connection to the database
conn = PG.connect( dbname: 'LINGI2172-M4-Step1', user: options[:username], password: options[:password] )

# 1. Acquire a table
conn.exec( acquire_table_request ) do |result|
  token = result[0]['acquire_table']
  puts "You scanned the codebar and your token is " + token
end


# 2. Order the first sparkling water
# Declare this query later because we need the token to be set
order_sparkling_water = "select order_drinks(#{token}, array[(6, 1)]::order_line[])"
conn.exec( order_sparkling_water ) do |result|
  puts "You ordered a sparkling water. The order id is " + result[0]['order_drinks']
end

# 3. Look at the bill
look_at_the_bill = "select issue_ticket(#{token});"
conn.exec( look_at_the_bill ) do |result|
  puts "You looked at the bill : " + result[0]['issue_ticket']
end

# 4. Order the second sparkling water
conn.exec( order_sparkling_water ) do |result|
  puts "You ordered a sparkling water. The order id is " + result[0]['order_drinks']
end

# 5. Look at the bill and pay by given 10€
pay_and_leave = "select pay_table(#{token}, 10.0)"
conn.exec( look_at_the_bill ) do |result|
  puts "You looked at the bill : " + result[0]['issue_ticket']
end
conn.exec( pay_and_leave ) do |result|
  puts "You have paid and you leave...it's sunny outside"
end

conn.close
