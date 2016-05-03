# LINGI2172_DATABASES - Mission 4 : Database programming

This project is organized in subfolders, one per step.

## Step 1
### Set up
Create a database named "LINGI2172-M4-Step1".

Run the SQL scripts in the numerated order in order to set up the database and the procedures.
### Test
To run the test script, run the procedure stored in the *07-script_sparkling_water.sql* file with the following SQL statement `select sparkling_water_scenario()`

## Step 2
The sparkling water scenario can be runned using the Ruby script named **sparkling_water.rb**. In order to run it, you must have
-  [ruby](https://www.ruby-lang.org/en/)
- the [ruby-pg](https://github.com/ged/ruby-pg) gem that can be installed with `gem install pg`

`Usage: ruby sparkling_water.rb [-u username] [-p password]`

## Step 3
For the step 3, we used Ruby with the [Sequel](http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html) gem. So you need to install it with ```gem install sequel``` before running the script.

The file **DBmanager.rb** contains all the code needed to connect to the database, create the schema and populate the table. It also define the methods of our little API.

The file **sparkling_water.rb** is a simple ruby script that uses the DBmanager to run the sparkling water scenario.

`Usage: ruby sparkling_water.rb [-u username] [-p password] [-d database_name]`

Note that you have to create an empty database and give its name as parameter to the script. The default name that will be used is "LINGI2172-M4-Step3".
