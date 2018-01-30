# require this file from your "config/environment.rb" (after rails has been loaded)
# to integrate the file_column extension into rails.

require 'file_column'
require 'file_column_helper'


module ActiveRecord # :nodoc:
  class Base # :nodoc:
    # make file_column method available in all active record decendants
    include FileColumn
    include FileColumn::Validations
  end
end

module ActionView # :nodoc:
  module Helpers # :nodoc:
    include FileColumnHelper
  end
end
