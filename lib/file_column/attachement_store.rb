module FileColumn
  module AttachementStore
    begin
      require 'aws-sdk'
      class S3Store
        HALF_AN_HOUR = 30 * 60

        def initialize(options)
          s3 = AWS::S3.new(:access_key_id => options[:access_key_id],
                           :secret_access_key => options[:secret_access_key])

          @url_expires = options[:url_expires] || HALF_AN_HOUR
          @bucket = s3.buckets[options[:bucket_name]]
        end

        def upload(path, local_file)
          @bucket.objects.create(s3_path(path, File.basename(local_file)), File.read(local_file))
        end

        def upload_dir(path, local_dir)
          @bucket.objects.with_prefix(s3_path(path)).delete_all
          Dir[File.join(local_dir, "*")].each do |f|
            upload(path, f)
          end
        end

        def read(path)
          object(path).read
        end

        def exists?(path)
          object(path).exists?
        end

        def url_for(path)
          object(path).url_for(:read, :expires => @url_expires)
        end

        def clear
          @bucket.clear!
        end

        private
        def object(path)
          @bucket.objects[s3_path(path)]
        end

        def s3_path(*paths)
          '/' + paths.join('/')
        end
      end
    rescue LoadError => e
      puts "Warning: can not load aws-sdk gem, s3 file store will be disabled"
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
