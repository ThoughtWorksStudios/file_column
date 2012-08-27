require File.dirname(__FILE__) + '/abstract_unit'


class AttachementStoreTest < Test::Unit::TestCase
  STORE_DIR = File.dirname(__FILE__)+"/public/entry"
  def setup
    FileColumn.store = :filesystem
  end

  def teardown
    FileColumn.store(STORE_DIR).clear
  end

  def test_use_builder_to_build_attachement_store
    assert_equal FileColumn::AttachementStore::FilesystemStore, FileColumn.store("/tmp/attachements").class
  end

  def test_upload_local_file_to_store
    file =  "/tmp/file_column_test/abc"
    FileUtils.mkdir_p(File.dirname(file))
    FileUtils.touch(file)
    store = FileColumn.store(STORE_DIR)

    store.upload("x/y/z", file)
    assert !store.exists?("x/abc")
    assert store.exists?("x/y/z/abc")
  end


  def test_upload_local_dir
    local_dir = "/tmp/file_column_test_for_#{name}"
    FileUtils.mkdir_p(local_dir)
    FileUtils.touch(File.join(local_dir, "a"))
    FileUtils.touch(File.join(local_dir, "b"))

    store = FileColumn.store(STORE_DIR)
    store.upload_dir("x/y/z", local_dir)

    assert store.exists?("x/y/z/a")
    assert store.exists?("x/y/z/b")
  end

  def test_upload_local_dir_with_replace_files
    local_dir = "/tmp/file_column_test_for_#{name}_old"
    FileUtils.mkdir_p(local_dir)
    FileUtils.touch(File.join(local_dir, "a"))

    store = FileColumn.store(STORE_DIR)
    store.upload_dir("x/y/z", local_dir)

    local_dir = "/tmp/file_column_test_for_#{name}_new"
    FileUtils.mkdir_p(local_dir)
    FileUtils.touch(File.join(local_dir, "b"))

    store = FileColumn.store(STORE_DIR)
    store.upload_dir("x/y/z", local_dir)


    assert store.exists?("x/y/z/b")
    assert !store.exists?("x/y/z/a")
  end


end
