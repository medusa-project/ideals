##
# Encapsulates an entry in `config/formats.yml`.
#
# Properties
#
# * `category`:             `archive`, `audio`, `binary`, `code`, `document`,
#                           `font`, `image`, or `video`
# * `extensions`:           Extensions that files of this type may have, in
#                           order of likelihood/preference.
# * `icon`:                 One of the files (minus extension) in
#                           `app/assets/images/fontawesome`
# * `long_name`:            Long name.
# * `media_types`:          IANA media types, in order of preference.
# * `derivative_generator`: Name of the tool used to generate derivative/
#                           representative images for the format. Supported
#                           values are `imagemagick` and `libreoffice`.
# * `short_name`:           Short name.
# * `viewer_method`:        Name of a {BitstreamsHelper} method that will
#                           render a viewer for the format.
#
class FileFormat

  attr_reader :category, :derivative_generator, :extensions, :icon, :long_name,
              :media_types, :short_name, :viewer_method

  KNOWN_FORMATS   = YAML.load_file(File.join(Rails.root, "config", "formats.yml")).deep_symbolize_keys
  YAML_PROPERTIES = %w(category derivative_generator extensions icon long_name
                       media_types short_name viewer_method)

  ##
  # @param ext [String]
  # @return [FileFormat, nil]
  # @see Bitstream#format
  #
  def self.for_extension(ext)
    ext      = ext.to_s.downcase
    format_h = KNOWN_FORMATS.find{ |k,v| v[:extensions].include?(ext) }
    format   = nil
    if format_h
      format = FileFormat.new
      YAML_PROPERTIES.each do |attr|
        format.instance_variable_set("@#{attr}", format_h[1][attr.to_sym])
      end
    end
    format
  end

  def ==(obj)
    obj.kind_of?(FileFormat) && self.short_name == obj.short_name
  end

  ##
  # @return [String] The {media_types first media type}.
  #
  def media_type
    media_types.first
  end

  def to_s
    self.short_name
  end

end