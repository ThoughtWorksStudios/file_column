require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

db = 'file_column_test.sqlite'

ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",
                                        :database => db)


load File.dirname(__FILE__) + "/fixtures/schema.rb"
