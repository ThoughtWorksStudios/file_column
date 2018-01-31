# This module contains helper methods for displaying and uploading files
# for attributes created by +FileColumn+'s +file_column+ method. It will be
# automatically included into ActionView::Base, thereby making this module's
# methods available in all your views.
module FileColumnHelper

  # Use this helper to create an upload field for a file_column attribute. This will generate
  # an additional hidden field to keep uploaded files during form-redisplays. For example,
  # when called with
  #
  #   <%= file_column_field("entry", "image") %>
  #
  # the following HTML will be generated (assuming the form is redisplayed and something has
  # already been uploaded):
  #
  #   <input type="hidden" name="entry[image_temp]" value="..." />
  #   <input type="file" name="entry[image]" />
  #
  # You can use the +option+ argument to pass additional options to the file-field tag.
  #
  # Be sure to set the enclosing form's encoding to 'multipart/form-data', by
  # using something like this:
  #
  #    <%= form_tag {:action => "create", ...}, :multipart => true %>
  def file_column_field(object, method, options={})
    result = ActionView::Helpers::InstanceTag.new(object.dup, method.to_s+"_temp", self).to_input_field_tag("hidden", {})
    result << ActionView::Helpers::InstanceTag.new(object.dup, method, self).to_input_field_tag("file", options)
  end

  # Creates an URL where an uploaded file can be accessed. When called for an Entry object with
  # id 42 (stored in <tt>@entry</tt>) like this
  #
  #   <%= url_for_file_column(@entry, "image")
  #
  # the following URL will be produced, assuming the file "test.png" has been stored in
  # the "image"-column of an Entry object stored in <tt>@entry</tt>:
  #
  #  /entry/image/42/test.png
  #
  # This will produce a valid URL even for temporary uploaded files, e.g. files where the object
  # they are belonging to has not been saved in the database yet.
  #
  # The URL produces, although starting with a slash, will be relative
  # to your app's root. If you pass it to one rails' +image_tag+
  # helper, rails will properly convert it to an absolute
  # URL. However, this will not be the case, if you create a link with
  # the +link_to+ helper. In this case, you can pass <tt>:absolute =>
  # true</tt> to +options+, which will make sure, the generated URL is
  # absolute on your server.  Examples:
  #
  #    <%= image_tag url_for_file_column(@entry, "image") %>
  #    <%= link_to "Download", url_for_file_column(@entry, "image", :absolute => true) %>
  #
  # If there is currently no uploaded file stored in the object's column this method will
  # return +nil+.
  def url_for_file_column(object, method, options=nil, store_url_for_options={})
    case object
    when String, Symbol
      object = instance_variable_get("@#{object.to_s}")
    end

    # parse options
    subdir = nil
    absolute = false
    if options
      case options
      when Hash
        subdir = options[:subdir]
        absolute = options[:absolute]
      when String, Symbol
        subdir = options
      end
    end

    context_path = absolute ? get_relative_url_for_rails(Rails::VERSION::MAJOR) : nil
    object.send("#{method}_download_url", context_path, subdir, store_url_for_options)

  end

  private
  def get_relative_url_for_rails(rails_version)
    (rails_version == 2 ? ActionController::Base.relative_url_root : Rails.application.config.action_controller.relative_url_root).to_s
  end

end
