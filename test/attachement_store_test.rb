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
    assert_equal FileColumn::AttachementStore::FilesystemStore, FileColumn.store("/var/attachements").class
  end

  def test_upload_to_store
    test_file =  "/tmp/file_column_test/abc"
    local_dir = File.dirname(test_file)
    FileUtils.mkdir_p(local_dir)
    FileUtils.touch(test_file)
    store = FileColumn.store(STORE_DIR)

    store.upload_dir(local_dir)
    assert store.exists?("abc")
  end

end
