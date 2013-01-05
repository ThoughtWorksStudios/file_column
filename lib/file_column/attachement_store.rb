module FileColumn
  module AttachementStore
    begin
      require 'aws-sdk'

      class S3Store

        CONTENT_TYPES = {
          "html" => "text/html",
          "htm" => "text/html",
          "shtml" => "text/html",
          "css" => "text/css",
          "xml" => "text/xml",
          "gif" => "image/gif",
          "jpeg" => "image/jpeg",
          "jpg" => "image/jpeg",
          "js" => "application/x-javascript",
          "atom" => "application/atom+xml",
          "rss" => "application/rss+xml",
          "json" => "application/json",
          "mml" => "text/mathml",
          "txt" => "text/plain",
          "jad" => "text/vnd.sun.j2me.app-descriptor",
          "wml" => "text/vnd.wap.wml",
          "htc" => "text/x-component",
          "png" => "image/png",
          "tif" => "image/tiff",
          "tiff" => "image/tiff",
          "wbmp" => "image/vnd.wap.wbmp",
          "ico" => "image/x-icon",
          "jng" => "image/x-jng",
          "bmp" => "image/x-ms-bmp",
          "svg" => "image/svg+xml",
          "jar" => "application/java-archive",
          "war" => "application/java-archive",
          "ear" => "application/java-archive",
          "hqx" => "application/mac-binhex40",
          "doc" => "application/msword",
          "pdf" => "application/pdf",
          "ps" => "application/postscript",
          "eps" => "application/postscript",
          "ai" => "application/postscript",
          "rtf" => "application/rtf",
          "xls" => "application/vnd.ms-excel",
          "ppt" => "application/vnd.ms-powerpoint",
          "wmlc" => "application/vnd.wap.wmlc",
          "xhtml" => "application/vnd.wap.xhtml+xml",
          "kml" => "application/vnd.google-earth.kml+xml",
          "kmz" => "application/vnd.google-earth.kmz",
          "7z" => "application/x-7z-compressed",
          "cco" => "application/x-cocoa",
          "jardiff" => "application/x-java-archive-diff",
          "jnlp" => "application/x-java-jnlp-file",
          "run" => "application/x-makeself",
          "pl" => "application/x-perl",
          "pm" => "application/x-perl",
          "prc" => "application/x-pilot",
          "pdb" => "application/x-pilot",
          "rar" => "application/x-rar-compressed",
          "rpm" => "application/x-redhat-package-manager",
          "sea" => "application/x-sea",
          "swf" => "application/x-shockwave-flash",
          "sit" => "application/x-stuffit",
          "tcl" => "application/x-tcl",
          "tk" => "application/x-tcl",
          "der" => "application/x-x509-ca-cert",
          "pem" => "application/x-x509-ca-cert",
          "crt" => "application/x-x509-ca-cert",
          "xpi" => "application/x-xpinstall",
          "zip" => "application/zip",
          "bin" => "application/octet-stream",
          "exe" => "application/octet-stream",
          "dll" => "application/octet-stream",
          "deb" => "application/octet-stream",
          "dmg" => "application/octet-stream",
          "eot" => "application/octet-stream",
          "iso" => "application/octet-stream",
          "img" => "application/octet-stream",
          "msi" => "application/octet-stream",
          "msp" => "application/octet-stream",
          "msm" => "application/octet-stream",
          "mid" => "audio/midi",
          "midi" => "audio/midi",
          "kar" => "audio/midi",
          "mp3" => "audio/mpeg",
          "ra" => "audio/x-realaudio",
          "3gpp" => "video/3gpp",
          "3gp" => "video/3gpp",
          "mpeg" => "video/mpeg",
          "mpg" => "video/mpeg",
          "mov" => "video/quicktime",
          "flv" => "video/x-flv",
          "mng" => "video/x-mng",
          "asx" => "video/x-ms-asf",
          "asf" => "video/x-ms-asf",
          "wmv" => "video/x-ms-wmv",
          "avi" => "video/x-msvideo"
        }

        HALF_AN_HOUR = 30 * 60

        def initialize(path_prefix, options)
          s3 = AWS::S3.new
          @path_prefix = path_prefix
          @url_expires = options[:url_expires] || HALF_AN_HOUR
          @bucket = s3.buckets[options[:bucket_name]]
          @namespace = Proc === options[:namespace] ? options[:namespace].call : options[:namespace]
        end

        def upload(path, local_file)
          local_file_name = File.basename(local_file)
          @bucket.objects.create(
                                 s3_path(path, local_file_name),
                                 File.read(local_file),
                                 { :content_type => derive_content_type(local_file_name) }
                                 )
        end

        def derive_content_type(file_name)
          file_extension = file_name.split(".").last
          CONTENT_TYPES[file_extension]
        end

        def upload_dir(path, local_dir)
          @bucket.objects.with_prefix(s3_path(path)).delete_all
          Dir[File.join(local_dir, "*")].each do |f|
            upload(path, f)
          end
        end

        def content_type(path)
          object(path).content_type
        end

        def copy(path, to_local_path)
          File.open(to_local_path, 'w') do |f|
            object(path).read do |c|
              f.write(c)
            end
          end
        end

        # should never use this in production code, it is only for test
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

      def copy(path, to_local_path)
        FileUtils.cp(absolute_path(path), to_local_path)
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
