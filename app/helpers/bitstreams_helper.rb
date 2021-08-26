module BitstreamsHelper

  ##
  # @return [String]
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