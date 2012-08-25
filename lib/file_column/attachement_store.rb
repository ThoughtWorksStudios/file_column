module FileColumn
  module AttachementStore
    class FilesystemStore
      def initialize(dir)
        @dir = dir
      end

      def upload_dir(local_dir)
        # remove old permament dir first
        # this creates a short moment, where neither the old nor
        # the new files exist but we can't do much about this as
        # filesystems aren't transactional.
        FileUtils.rm_rf @dir
        FileUtils.mv local_dir, @dir
      end

      def clear
        FileUtils.rm_rf @dir
      end
    end

    class Builder
      def initialize(*build_opts)
        @type, *@build_opts = *build_opts
      end

      # build the real storage
      # e.g Builder.new(:filesystem).build("/var/attachements")
      # oor  Builder.new(:filesystem, "/var/attachements").build
      def build(dir)
        store_class.new(*(@build_opts + [dir]))
      end

      private

      def store_class
        ActiveSupport::Inflector.constantize("FileColumn::AttachementStore::#{ActiveSupport::Inflector.camelize(@type)}Store")
      end
    end
  end
end
