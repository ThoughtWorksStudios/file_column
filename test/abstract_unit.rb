require 'thread'
require 'test/unit'
require 'rubygems'
require 'active_support'
require 'active_record'
require 'action_view'
require 'action_controller'
require File.dirname(__FILE__) + '/connection'
require 'stringio'

RAILS_ROOT = File.dirname(__FILE__)
RAILS_ENV = ""

$: << "../lib"

class Rails
  @root = File.dirname(__FILE__)

  class << self
    attr_accessor :root
  end

  class VERSION
    MAJOR = (ENV['RAILS_VERSION'] || '2').to_i
  end
end


require 'file_column'
require 'file_column_helper'
require 'file_compat'
require 'test_case'

# do not use the file executable normally in our tests as
# it may not be present on the machine we are running on
FileColumn::ClassMethods::DEFAULT_OPTIONS =
  FileColumn::ClassMethods::DEFAULT_OPTIONS.merge({:file_exec => nil})

class ActiveRecord::Base
    include FileColumn
    include FileColumn::Validations
end


class RequestMock
  attr_accessor :relative_url_root

  def initialize
    @relative_url_root = ""
  end
end

class Test::Unit::TestCase

  def assert_equal_paths(expected_path, path)
    assert_equal normalize_path(expected_path), normalize_path(path)
  end


  private

  def normalize_path(path)
    Pathname.new(path).realpath
  end

  def clear_validations
    [:validate, :validate_on_create, :validate_on_update].each do |attr|
        Entry.write_inheritable_attribute attr, []
        Movie.write_inheritable_attribute attr, []
      end
  end

  def file_path(filename)
    File.expand_path("#{File.dirname(__FILE__)}/fixtures/#{filename}")
  end

  alias_method :f, :file_path
end

# provid a dummy storage implementation for tests

class InMemoryWithUrlStorageStore
  def initialize(path_prefix, options)
    @path_prefix = path_prefix
    @storage = {}
  end
  def upload(path, file)
    @storage[absolute_path(path) + "/" + File.basename(file)] = File.read(file)
  end

  def upload_dir(path, local_dir)
    Dir[File.join(local_dir, "*")].each do |f|
      upload(path, f)
    end
  end

  def exists?(path)
    File.key?(path)
  end

  def url_for(path, options={})
    "store generated url for #{path} with options #{options.inspect}"
  end

  def absolute_path(path)
    File.join(@path_prefix, path)
  end

  def clear
    @storage = {}
  end
end

Storage.add_store_class(:in_memory_with_url, InMemoryWithUrlStorageStore)
