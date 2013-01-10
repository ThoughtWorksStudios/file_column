require File.dirname(__FILE__) + '/abstract_unit'
require 'active_support/test_case'

class AttachementStoreTest < Test::Unit::TestCase
  extend Test::Unit::Assertions

  ROOT_DIR = File.dirname(__FILE__)+"/public/entry"
  STORE_BUILD_OPTS = {
    :filesystem => {:root_path => ROOT_DIR },
    :s3 => {:bucket_name => ENV["S3_BUCKET_NAME"]}}

  def teardown
    FileUtils.rm_rf("/tmp/file_column_test")
  end

  def self.storage_configured?(store_type)
    return !ENV["AWS_ACCESS_KEY_ID"].blank? if store_type == :s3
    true
  end

  def self.store_test(test_name, store_type, build_opts, &block)
    define_method(test_name + "_for_#{store_type}_store") do
      if !self.class.storage_configured?(store_type)
        puts "Warning #{store_type} storage is not configured, test will be ignored"
        return
      end
      FileColumn.config_store(store_type, build_opts)
      store = FileColumn.store("foo")
      begin
        yield(store)
      ensure
        store.clear
      end
    end
  end

  def self.create_local_file(path, content="abc")
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "w+") { |f| f << content }
    path
  end


  STORE_BUILD_OPTS.each do |store_type, build_opts|
    store_test "test_build_right_store", store_type, build_opts do |store|
      assert store.class.name.include?(ActiveSupport::Inflector.camelize(store_type))
    end

    store_test "test_upload_local_file", store_type, build_opts do |store|
      store.upload("x/y/z", create_local_file("/tmp/file_column_test/abc", "123"))
      assert !store.exists?("x/abc")
      assert store.exists?("x/y/z/abc")
      assert_equal "123", store.read("x/y/z/abc")
    end

    store_test "test_clear_store", store_type, build_opts do |store|
      store_a = FileColumn.store('foo')
      store_b = FileColumn.store('bar')
      store_a.upload("x/y/z", create_local_file("/tmp/file_column_test/abc"))
      store_b.upload("x/y/z", create_local_file("/tmp/file_column_test/abc"))

      assert store_a.exists?("x/y/z/abc")
      assert store_b.exists?("x/y/z/abc")

      store_a.clear

      assert !store_a.exists?("x/y/z/abc")
      assert store_b.exists?("x/y/z/abc")

      store_b.clear

      assert !store_a.exists?("x/y/z/abc")
      assert !store_b.exists?("x/y/z/abc")
    end

    store_test "test_delete_files_under_a_path", store_type, build_opts do |store|
      store.upload("x/y/z", create_local_file("/tmp/file_column_test/a"))
      store.upload("x/y/z/k", create_local_file("/tmp/file_column_test/b"))
      store.upload("x/y/s", create_local_file("/tmp/file_column_test/c"))


      store.delete("x/y/z")
      assert !store.exists?("x/y/z/a")
      assert !store.exists?("x/y/z/k/b")
      assert store.exists?("x/y/s/c")
    end


    store_test "test_upload_with_same_name_replace_file", store_type, build_opts do |store|
      store.upload("x/y/z", create_local_file("/tmp/file_column_test/abc", "123"))
      assert_equal "123", store.read("x/y/z/abc")

      store.upload("x/y/z", create_local_file("/tmp/file_column_test/abc", "456"))
      assert_equal "456", store.read("x/y/z/abc")
    end

    store_test "test_upload_local_dir", store_type, build_opts do |store|
      create_local_file("/tmp/file_column_test/a")
      create_local_file("/tmp/file_column_test/b")
      store.upload_dir("x/y/z", "/tmp/file_column_test")

      assert store.exists?("x/y/z/a")
      assert store.exists?("x/y/z/b")
    end


    store_test "test_upload_local_dir_with_replace_files", store_type, build_opts do |store|

      create_local_file("/tmp/file_column_test/old/a")
      store.upload_dir("x/y/z", "/tmp/file_column_test/old")

      create_local_file("/tmp/file_column_test/new/b")
      store.upload_dir("x/y/z", "/tmp/file_column_test/new")

      assert store.exists?("x/y/z/b")
      assert !store.exists?("x/y/z/a")
    end

    store_test 'test_copy_file_to_local_path', store_type, build_opts do |store|
      create_local_file("/tmp/file_column_test/old/a")
      store.upload_dir("x/y/z", "/tmp/file_column_test/old")
      FileUtils.mkdir_p('/tmp/file_column_test/new')
      store.copy('x/y/z/a', '/tmp/file_column_test/new/a')
      assert_equal 'abc', File.read('/tmp/file_column_test/new/a')
    end

    store_test 'test_should_not_create_local_file_if_the_file_does_not_exist_on_s3', store_type, build_opts do |store|
      FileUtils.mkdir_p('/tmp/file_column_test')
      assert_raise RuntimeError do
        store.copy('xx', '/tmp/file_column_test/xx')
      end
      assert !File.exists?('/tmp/file_column_test/xx')
    end
  end


  if storage_configured?(:s3)
    def test_generate_signed_url_for_s3_store
      FileColumn.config_store(:s3, STORE_BUILD_OPTS[:s3])
      self.class.create_local_file("/tmp/file_column_test/a.jpg")

      store = FileColumn.store("foo")
      store.upload_dir("x/y/z", "tmp/file_column_test")
      url = URI.parse(store.url_for("x/y/z/a.jpg"))
      assert url.path.include?("/foo/x/y/z/a.jpg")
      assert url.query.include?("Signature")
      assert url.query.include?("Expires")
    end

    def test_use_s3_bucket_storage_with_namespace
      FileColumn.config_store(:s3, STORE_BUILD_OPTS[:s3].merge(:namespace => 'app_namespace'))
      local_file = self.class.create_local_file("/tmp/file_column_test/a.jpg")
      store = FileColumn.store("foo")

      store.upload("x/y/z", local_file)

      url = URI.parse(store.url_for("x/y/z/a.jpg"))
      assert url.path.include?("/app_namespace/foo/x/y/z/a.jpg")
    end

    def test_use_s3_storage_namespace_can_be_a_lazy_evaluate_block
      ever_changing_app_namespace = 'foo'
      FileColumn.config_store(:s3, STORE_BUILD_OPTS[:s3].merge(:namespace => proc { ever_changing_app_namespace } ))

      ever_changing_app_namespace = 'bar'

      local_file = self.class.create_local_file("/tmp/file_column_test/a.jpg")
      store = FileColumn.store("foo")
      store.upload("x/y/z", local_file)
      url = URI.parse(store.url_for("x/y/z/a.jpg"))
      assert url.path.include?("/bar/foo/x/y/z/a.jpg")
    end


    def test_sets_content_type_on_uploaded_files
      FileColumn.config_store(:s3, STORE_BUILD_OPTS[:s3].merge(:namespace => 'app_namespace'))
      local_file = self.class.create_local_file("/tmp/file_column_test/a.jpg")
      store = FileColumn.store("foo")

      store.upload("x/y/z", local_file)
      assert_equal "image/jpeg", store.content_type("x/y/z/a.jpg")
    end

    def test_ignores_content_type_if_none_found
      FileColumn.config_store(:s3, STORE_BUILD_OPTS[:s3].merge(:namespace => 'app_namespace'))
      local_file = self.class.create_local_file("/tmp/file_column_test/a")
      store = FileColumn.store("foo")

      store.upload("x/y/z", local_file)
      assert_equal "", store.content_type("x/y/z/a")
    end
  end
end
