require 'sequel' # NOTE: Sequel uses autocommit mode by default
require 'optparse'

# Parse args
options = {:username => "postgres", :database => "LINGI2172-M4-Step3"}
OptionParser.new do |opts|
  opts.banner = "Usage: sparkling_water.rb [-u username] [-p password] [-d database_name]"
  opts.on('-u', '--optional username', 'Username to connect to database. Default value is "postgres"') { |v| options[:username] = v }
  opts.on('-p', '--require password', 'Password to connect to database') { |v| options[:password] = v }
  opts.on('-d', '--optional database', 'An empty, existing, database that the provided user can access and modify. Default value is "LINGI2172-M4-Step3"') { |v| options[:database] = v }
end.parse!

# Establish database connection
DB = Sequel.connect("postgres://#{options[:username]}:#{options[:password]}@localhost:5432/#{options[:database]}")

# Create the schema of the database
new_database = true # a custom boolean value that will be used later to know if we need to populate the database or not
begin
  puts 'Creating schema...'
  # The table creation process is quiet easy
  DB.transaction do # encapsulate this in a transaction because we want ALL the tables to exists or NONE
    DB.create_table :tables do
      primary_key :table_id # by default the primary_key will be of type SERIAL
    end

    DB.create_table :clients do
      primary_key :token_id
    end

    DB.create_table :placements do
      primary_key [:client_id, :table_id] # we can define multiple primary_keys
      foreign_key :table_id, :tables, :unique=>true # we can also define some constraint like UNIQUE
      foreign_key :client_id, :clients
    end

    DB.create_table :drinks do
      primary_key :drink_id
      Float :price, :null=>false
      String :name, :null=>false
      String :description
    end

    DB.create_table :orders do
      primary_key :order_id
      DateTime :order_time
      foreign_key :passes_by, :clients
    end

    DB.create_table :ordered_drinks do
      primary_key [:order_id, :drink_id]
      foreign_key :order_id, :orders
      foreign_key :drink_id, :drinks
      Integer :qty, :null=>false
    end

    DB.create_table :payments do
      primary_key :payment_id
      Float :amount_paid
      foreign_key :made_by, :clients
    end
  end # COMMIT
  puts 'Done'
rescue # an error is raised if one of the table already exists in the database. In that case, it means the schema already exists in the database and that we won't have to populate the tables
  puts "Schema arleady exist in the database"
  new_database = false
end

# Create the dataset classes used to access the database via Sequel
# Sequel will automatically retrieve the structure of the tables from the database and provide the accessors and mutators for the classes
class Table < Sequel::Model # Sequel consider that the table name is the same as the class name but with lower case letter and in the plural form => gives the 'tables' table
end
class Client < Sequel::Model #gives the 'clients' table
  one_to_many :orders, :key=>:passes_by # we can define some relations between the classes. This will give us the possibility to simply do client.orders to retrieve all the orders made by a client. Sequel will automatically build the query SELECT * FROM orders WHERE passes_by = client.token_id. NOTE: we must manually indicate the KEY because Sequel can not extrapolate it by itself. It will think that the key is 'client_id' while it is 'passes_by'
end
class Placement < Sequel::Model #gives the 'placements' table
end
class Drink < Sequel::Model #gives the 'drinks' table
  one_to_many :ordered_drinks
end
class Order < Sequel::Model #gives the 'orders' table
  many_to_one :client, :key=>:token_id # many_to_one is the opposite of one_to_many. It indicates that many orders can be associated to one client
  one_to_many :ordered_drinks
end
class OrderedDrink < Sequel::Model #gives the 'ordered_drinks' table
  many_to_one :order
  many_to_one :drink
end
class Payment < Sequel::Model #gives the 'payments' table
  many_to_one :client
end

# Populate the database with some placeholders data if it is a new database
if(new_database)
  puts 'Populating database...'
  Table.create() # the table_id will automatically be 1, because its type is SERIAL
  Table.create() # 2
  Table.create() # 3
  Table.create() # 4
  Table.create() # 5
  Table.create() # 6
  Drink.create(:price => 3.9, :name => 'Desperados', :description => 'Tequila beer')            # 1
  Drink.create(:price => 1.5, :name => 'Jupiler', :description => 'Les hommes savent pourquoi') # 2
  Drink.create(:price => 1.5, :name => 'Canada dry', :description => 'Ginger sode')             # 3
  Drink.create(:price => 3.0, :name => 'Barbar', :description => 'Honey beer')                  # 4
  Drink.create(:price => 3.5, :name => 'Pecheresse', :description => 'Girl friendly beer')      # 5
  Drink.create(:price => 1.0, :name => 'Sparkling water', :description => 'Good for health')    # 6 => we will use this ID to order a sparkling water
  puts 'Done'
end

# Declare the functions

# IN: a table barcode
# OUT: a client token
# PRE: the table is free
# POST: the table is no longer free
# POST: issued token can be used for ordering drinks
def acquire_table(codebar)
  begin
    client = nil
    DB.transaction do # new explicit transaction to avoid that the generated token at line 120 remains if the table is not free
      client = Client.create() # we can create a client in the databse simply like this. Sequel convert it to a SQL statement INSERT INTO clients ...
      p = Placement.new # The other way to create a row in the database is by first creating the object
      p.client_id = client.token_id # then setting its attributes
      p.table_id = codebar
      p.save # And finally save it; This is equivalent to => Placement.create(:client_id => client.token_id, :table_id => codebar)
    end # COMMIT
    return client.token_id
  rescue # an error is raised if a row with the same table_id already exists in placements. Thanks to the UNIQUE constraint
    raise 'This table is not free'
  end
end

# IN: a token
# OUT: TRUE if the token is a valid token that can be used to order drinks
# OUT : FALSE otherwise
def is_token_valid(token)
  return Placement[:client_id => token] != nil # just check if a there is a Placement with the given token in the database. Note how easy it is to retrieve a row with a condition and convert it to an instance of a class
end

# IN: a client token
# IN: a list of order lines
# OUT: the unique number of the created order
# PRE: the client token is valid and correspond to an occupied table
# POST: the order is created, its number is the one returned
# usage : my_order = [{:drink_id=>1, :qty=>1}, {:drink_id=>2, :qty=>1}]
# =>       order_drinks(token, my_order)
def order_drinks(token, order_lines)
  if is_token_valid token
    order = nil
    DB.transaction do # new transaction: if something goes wrong, no order and no order_lines will be created
      order = Order.create(:order_time => Time.now, :passes_by => token)
      order_lines.each do |line| # iterate over the array and do something for each of its value
        od = OrderedDrink.new
        od.order_id = order.order_id
        od.drink_id = line[:drink_id]
        od.qty = line[:qty]
        od.save # OrderedDrink.create(:order_id => order.order_id, :drink_id => line[:drink_id], :qty => line[:qty])
      end
    end # COMMIT
    return order.order_id
  else
    raise 'The provided token is not valid'
  end
end

# IN: a client token
# OUT: the ticket to be paid, with a summary of orders (which drinks in which quantities) and total amount to pay
# PRE: the client token is valid and correspond to an occupied table
# POST: issued ticke correspond to all (and only) ordered drinks at that table
def issue_ticket(token)
  if is_token_valid token # NOTE: we don't need a transaction here because we are just reading data. For each query done to the databse, Sequel will automatically wrap it in a transaction
    total = 0.0
    details = []
    client = Client[:token_id => token] # Easy way to retrieve a client based on its token_id
    client.orders.each { |order| # Here, we are using the one_to_many property that we used on line 71. Thanks to this, Sequel can give us an array of orders linked to  the client.
      order.ordered_drinks.each { |ordered_drink| # And again, we use the one_to_many property from Order to get all the OrderedDrink values
        total += ordered_drink.qty * ordered_drink.drink.price
        details.push({:name => ordered_drink.drink.name, :qty => ordered_drink.qty}) # add to the array a new Hash. The keys are :name and :qty
      }
    }
    return {:total => total, :details => details} # return a new Hash
  else
    raise 'The provided token is not valid'
  end
end

# IN: a client token
# IN: an amount paid
# OUT:
# PRE: the client token is valid
# PRE: The input amount >= amount due for the table
# POST: the table is released
# POST: the client token can no longer be used to order drinks
def pay_table(token, amount)
  if is_token_valid token
    DB.transaction do # new transaction to be sure that nothing change on the database while we operate the payment
      ticket = issue_ticket(token) # let's use the issue_ticket method to compute the total price to pay
      if amount < ticket[:total]
        raise "the given amount must be greater or equal to #{ticket[:total]}" # the error produce a ROLLBACK of the transaction
      else
        Placement[:client_id => token].destroy # we retrieve the Placement associated to the token and delete it from the database
      end
    end # COMMIT the transaction
    return
  else
    raise 'The provided token is not valid'
  end
end
