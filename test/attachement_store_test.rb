require File.dirname(__FILE__) + '/abstract_unit'


class AttachementStoreTest < Test::Unit::TestCase
  def test_use_builder_to_build_attachement_store
    FileColumn.store = :filesystem
    assert_equal FileColumn::AttachementStore::FilesystemStore, FileColumn.store("/var/attachements").class
 end

end
