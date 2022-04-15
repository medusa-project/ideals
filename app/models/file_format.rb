##
# Encapsulates an entry in `config/formats.yml`.
#
# Properties
#
# * `category`:         `archive`, `audio`, `binary`, `code`, `document`,
#                       `image`, or `video`
# * `extensions`:       Extensions that files of this type may have, in order
#                       of likelihood/preference.
# * `icon`:             One of the files (minus extension) in
#                       `app/assets/images/fontawesome`
# * `long_name`:        Long name.
# * `media_types`:      IANA media types, in order of preference.
# * `readable_by_vips`: Whether this type is supported by our image processing
#                       library (VIPS) in order to generate representative
#                       images.
# * `short_name`:       Short name.
# * `viewer_method`:    Name of a [BitstreamsHelper] method that will render
#                       a viewer for the format.
#
class FileFormat

  attr_reader :category, :extensions, :icon, :long_name, :media_types,
              :readable_by_vips, :short_name, :viewer_method

  KNOWN_FORMATS = YAML.load_file(File.join(Rails.root, "config", "formats.yml")).deep_symbolize_keys

  ##
  # @param ext [String]
  # @return [FileFormat, nil]
  # @see Bitstream@format
  #
  def self.for_extension(ext)
    ext      = ext.to_s.downcase
    format_h = KNOWN_FORMATS.find{ |k,v| v[:extensions].include?(ext) }
    format   = nil
    if format_h
      format = FileFormat.new
      %w(category extensions icon long_name media_types readable_by_vips short_name viewer_method).each do |attr|
        format.instance_variable_set("@#{attr}", format_h[1][attr.to_sym])
      end
    end
    format
  end

end