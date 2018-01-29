class Entry < ActiveRecord::Base

  after_save :after_save_method

  def after_assign
    @after_assign_called = true
  end

  def after_assign_called?
    @after_assign_called
  end

  def after_save_method
    @after_save_called = true
  end

  def after_save_called?
    @after_save_called
  end

  def my_store_dir
    # not really dynamic but at least it could be...
    "my_store_dir"
  end
end
