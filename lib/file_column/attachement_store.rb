module FileColumn
  module AttachementStore
    class FilesystemStore
      def initialize(dir)
        @dir = dir
        FileUtils.mkdir_p @dir
      end

      def upload(path, local_file)
        FileUtils.mkdir_p(absolute_path(path))
        FileUtils.mv(local_file, absolute_path(path))
      end

      def upload_dir(path, local_dir)
        FileUtils.rm_rf(absolute_path(path))
        Dir[File.join(local_dir, "*")].each do |f|
          upload(path, f)
        end
      end

      #todo: this should be interface that retrive a lazy file object
      def absolute_path(*relative_paths)
        File.join(@dir, *relative_paths)
      end

      def exists?(file_path)
        File.exists?(absolute_path(file_path))
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
