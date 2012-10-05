module FileColumn
  module AttachementStore
    begin
      require 'aws-sdk'

      class S3Store
        HALF_AN_HOUR = 30 * 60

        def initialize(path_prefix, options)
          s3 = AWS::S3.new(:access_key_id => options[:access_key_id],
                           :secret_access_key => options[:secret_access_key])
          @path_prefix = path_prefix
          @url_expires = options[:url_expires] || HALF_AN_HOUR
          @bucket = s3.buckets[options[:bucket_name]]
          @namespace = options[:namespace]
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
          object(path).url_for(:read, :expires => @url_expires).to_s
        end

        #todo: this should be interface that retrive a lazy file object
        def absolute_path(*relative_paths)
          File.join("s3:#{@bucket.name}://", *relative_paths)
        end

        def delete(path)
          @bucket.objects.with_prefix(s3_path(path)).delete_all
        end

        def clear
          if s3_path.blank?
            @bucket.clear
          else
            @bucket.objects.with_prefix(s3_path).delete_all
          end
        end

        private
        def object(path)
          @bucket.objects[s3_path(path)]
        end

        def s3_path(*paths)
          File.join(*([@namespace, @path_prefix, *paths].compact))
        end
      end
    rescue LoadError => e
      puts "Warning: can not load aws-sdk gem, s3 file store will be disabled"
    end

    class FilesystemStore
      def initialize(path_prefix, options={})
        @dir = options[:root_path] || raise('Must define root path for file system store')
        @path_prefix = path_prefix
        FileUtils.mkdir_p File.join(@dir, @path_prefix)
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
        File.join(@dir, @path_prefix, *relative_paths)
      end

      def exists?(path)
        File.exists?(absolute_path(path))
      end

      def delete(path)
        FileUtils.rm_rf(absolute_path(path))
      end

      def clear
        FileUtils.rm_rf File.join(@dir, @path_prefix)
      end
    end

    class Builder
      def initialize(type, build_opts={})
        @type, @build_opts = type, build_opts
      end

      def build(path_prefix, extra_opts={})
        store_class.new(path_prefix, @build_opts.merge(extra_opts))
      end

      private

      def store_class
        ActiveSupport::Inflector.constantize("FileColumn::AttachementStore::#{ActiveSupport::Inflector.camelize(@type)}Store")
      end
    end
  end
end
