module FileColumn
  module AttachementStore
    class S3Store
      def initialize(options)
        @api_key_id = options[:access_key_id]
        @api_access_key = options[:secret_access_key]
        @bucket_name = options[:bucket_name]
      end

      def upload(path, local_file)
      end

      def upload_dir(path, local_dir)
      end

      def exists?(file_path)
      end

      def clear
      end
    end

    class FilesystemStore
      def initialize(dir)
        @dir = dir
        FileUtils.mkdir_p @dir
      end

      def read(path)
        File.read(absolute_path(path))
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

      def build(dir=nil)
        args = @build_opts
        args += [dir] if @type == :filesystem
        store_class.new(*args)
      end

      private

      def store_class
        ActiveSupport::Inflector.constantize("FileColumn::AttachementStore::#{ActiveSupport::Inflector.camelize(@type)}Store")
      end
    end
  end
end
