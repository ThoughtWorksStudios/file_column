require File.dirname(__FILE__) + '/abstract_unit'
require 'active_support/test_case'

class AttachementStoreTest < Test::Unit::TestCase
  extend Test::Unit::Assertions

  STORE_DIR = File.dirname(__FILE__)+"/public/entry"
  STORE_BUILD_OPTS = [[:filesystem]]
  if !ENV["S3_ACCESS_KEY_ID"].blank?
    STORE_BUILD_OPTS << [:s3, {
                           :access_key_id => ENV["S3_ACCESS_KEY_ID"],
                           :secret_access_key => ENV["S3_SECRET_ACCESS_KEY"],
                           :bucket_name => ENV["S3_BUCKET_NAME"]}]
  end

  def teardown
    FileColumn.store(STORE_DIR).clear
    FileUtils.rm_rf("/tmp/file_column_test")
  end

  def self.store_test(test_name, store_type, *store_building_args, &block)
    define_method(test_name + "_for_#{store_type}_store") do
      FileColumn.store = store_type, *store_building_args
      yield
    end
  end


  STORE_BUILD_OPTS.each do |store_type, *rest_args|
    store_test "test_build_right_store", store_type, *rest_args do
      assert  FileColumn.store("/tmp/attachements").class.name.include?(ActiveSupport::Inflector.camelize(store_type))
    end

    store_test "test_upload_local_file", store_type, *rest_args do
      file =  "/tmp/file_column_test/abc"
      FileUtils.mkdir_p(File.dirname(file))
      FileUtils.touch(file)
      store = FileColumn.store(STORE_DIR)
      store.upload("x/y/z", file)
      assert !store.exists?("x/abc")
      assert store.exists?("x/y/z/abc")
      assert_equal "", store.read("x/y/z/abc")
    end

    store_test "test_upload_with_same_name_replace_file", store_type, *rest_args do
      file =  "/tmp/file_column_test/abc"
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w+") { |f| f << "123" }

      store = FileColumn.store(STORE_DIR)
      store.upload("x/y/z", file)

      assert_equal "123", store.read("x/y/z/abc")

      File.open(file, "w+") { |f| f << "456" }
      store.upload("x/y/z", file)

      assert_equal "456", store.read("x/y/z/abc")
    end

    store_test "test_upload_local_dir", store_type, *rest_args do
      local_dir = "/tmp/file_column_test"
      FileUtils.mkdir_p(local_dir)
      FileUtils.touch(File.join(local_dir, "a"))
      FileUtils.touch(File.join(local_dir, "b"))

      store = FileColumn.store(STORE_DIR)
      store.upload_dir("x/y/z", local_dir)

      assert store.exists?("x/y/z/a")
      assert store.exists?("x/y/z/b")
    end


    store_test "test_upload_local_dir_with_replace_files", store_type, *rest_args do

      local_dir = "/tmp/file_column_test/old"
      FileUtils.mkdir_p(local_dir)
      FileUtils.touch(File.join(local_dir, "a"))

      store = FileColumn.store(STORE_DIR)
      store.upload_dir("x/y/z", local_dir)

      local_dir = "/tmp/file_column_test/new"
      FileUtils.mkdir_p(local_dir)
      FileUtils.touch(File.join(local_dir, "b"))

      store = FileColumn.store(STORE_DIR)
      store.upload_dir("x/y/z", local_dir)

      assert store.exists?("x/y/z/b")
      assert !store.exists?("x/y/z/a")
    end

  end
end
