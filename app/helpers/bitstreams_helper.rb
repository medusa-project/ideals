# frozen_string_literal: true

module BitstreamsHelper

  ##
  # Returns an `img` tag for the given bitstream. If the bitstream
  # {Bitstream#has_representative_image? has a representative image}, that is
  # used. Otherwise, an appropriate generic icon is chosen based on the
  # {FileFormat} registry.
  #
  # @param bitstream [Bitstream]
  # @param region [Symbol] See {Bitstream#derivative_url}.
  # @param size [Integer] See {Bitstream#derivative_url}. This is the literal
  #                       size of the image; the `img` tag has no `width`/
  #                       `height` attribute and must be sized via CSS.
  # @return [String] HTML `img` tag.
  #
  def representative_image_tag(bitstream,
                               region: :full,
                               size:)
    if bitstream.has_representative_image?
      path = bitstream.derivative_url(region: region, size: size)
    else
      ext    = bitstream.original_filename.split(".").last.downcase
      format = FileFormat.for_extension(ext)
      icon   = format&.icon || "file-o"
      path   = image_path("fontawesome/#{icon}.svg")
    end
    # data-type helps to select it via CSS
    image_tag(path, "data-tyoe": "svg")
  end

end