require File.dirname(__FILE__) + '/abstract_unit'
require 'active_support/test_case'

class AttachementStoreTest < Test::Unit::TestCase
  extend Test::Unit::Assertions

  ROOT_DIR = File.dirname(__FILE__)+"/public/entry"
  STORE_BUILD_OPTS = [[:filesystem, {:root_path => ROOT_DIR } ]]

  if !ENV["S3_ACCESS_KEY_ID"].blank?
    STORE_BUILD_OPTS << [:s3, {
                           :access_key_id => ENV["S3_ACCESS_KEY_ID"],
                           :secret_access_key => ENV["S3_SECRET_ACCESS_KEY"],
                           :bucket_name => ENV["S3_BUCKET_NAME"]}]
  end

  def teardown
    FileUtils.rm_rf("/tmp/file_column_test")
  end

  def self.store_test(test_name, store_type, build_opts, &block)
    define_method(test_name + "_for_#{store_type}_store") do
      FileColumn.config_store(store_type, build_opts)
      store = FileColumn.store("foo")
      begin
        yield(store)
      ensure
        store.clear
      end
    end
  end

  STORE_BUILD_OPTS.each do |store_type, build_opts|
    store_test "test_build_right_store", store_type, build_opts do |store|
      assert store.class.name.include?(ActiveSupport::Inflector.camelize(store_type))
    end

    store_test "test_upload_local_file", store_type, build_opts do |store|
      file =  "/tmp/file_column_test/abc"
      FileUtils.mkdir_p(File.dirname(file))
      FileUtils.touch(file)
      store.upload("x/y/z", file)
      assert !store.exists?("x/abc")
      assert store.exists?("x/y/z/abc")
      assert_equal "", store.read("x/y/z/abc")
    end

    store_test "test_upload_with_same_name_replace_file", store_type, build_opts do |store|
      file =  "/tmp/file_column_test/abc"
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file, "w+") { |f| f << "123" }

      store.upload("x/y/z", file)

      assert_equal "123", store.read("x/y/z/abc")

      File.open(file, "w+") { |f| f << "456" }
      store.upload("x/y/z", file)

      assert_equal "456", store.read("x/y/z/abc")
    end

    store_test "test_upload_local_dir", store_type, build_opts do |store|
      local_dir = "/tmp/file_column_test"
      FileUtils.mkdir_p(local_dir)
      FileUtils.touch(File.join(local_dir, "a"))
      FileUtils.touch(File.join(local_dir, "b"))

      store.upload_dir("x/y/z", local_dir)

      assert store.exists?("x/y/z/a")
      assert store.exists?("x/y/z/b")
    end


    store_test "test_upload_local_dir_with_replace_files", store_type, build_opts do |store|

      local_dir = "/tmp/file_column_test/old"
      FileUtils.mkdir_p(local_dir)
      FileUtils.touch(File.join(local_dir, "a"))

      store.upload_dir("x/y/z", local_dir)

      local_dir = "/tmp/file_column_test/new"
      FileUtils.mkdir_p(local_dir)
      FileUtils.touch(File.join(local_dir, "b"))

      store = FileColumn.store("foo")
      store.upload_dir("x/y/z", local_dir)

      assert store.exists?("x/y/z/b")
      assert !store.exists?("x/y/z/a")
    end
  end


  if STORE_BUILD_OPTS[1]
    def test_generate_signed_url_for_s3_store
      FileColumn.config_store(*STORE_BUILD_OPTS[1])
      local_dir = "/tmp/file_column_test"
      FileUtils.mkdir_p(local_dir)
      FileUtils.touch(File.join(local_dir, "a.jpg"))

      store = FileColumn.store("foo")
      store.upload_dir("x/y/z", local_dir)
      url = URI.parse(store.url_for("x/y/z/a.jpg"))
      assert url.path.include?("/foo/x/y/z/a.jpg")
      assert url.query.include?("Signature")
      assert url.query.include?("Expires")
    end
  end
end
