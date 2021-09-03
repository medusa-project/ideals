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
  # @param attrs [Hash] Additional tag attributes.
  # @return [String] HTML `img` tag.
  #
  def representative_image_tag(bitstream,
                               region: :full,
                               size:,
                               **attrs)
    path = nil
    if bitstream.has_representative_image?
      begin
        path = bitstream.derivative_url(region: region, size: size)
        svg  = false
      rescue
        # The object may not exist, or something else is wrong, but we can't
        # do anything about it here.
      end
    end
    unless path
      format = bitstream.format
      icon   = format&.icon || "file-o"
      path   = image_path("fontawesome/white/#{icon}.svg")
      svg    = true
    end
    # data-type helps to select it via CSS
    image_tag(path, {"data-svg": svg}.merge(attrs))
  end

  ##
  # @param bitstream [Bitstream]
  # @return [String]
  #
  def viewer_for(bitstream)
    format = bitstream.format
    if format
      method = format.viewer_method
      if method
        return send(method, bitstream)
      end
    end
    no_viewer_for(bitstream)
  end


  private

  def audio_tag_for(bitstream)
    html = StringIO.new
    html << "<audio controls>"
    html <<   "<source src=\"#{bitstream.presigned_url}\" type=\"#{bitstream.media_type}\">"
    html <<   no_viewer_for(bitstream)
    html << "</audio>"
    raw(html.string)
  end

  def image_tag_for(bitstream)
    representative_image_tag(bitstream, size: 2048)
  end

  def no_viewer_for(bitstream)
    html = StringIO.new
    html << "<div class=\"unsupported-format\">"
    html <<   "<p class=\"format-name\">"
    html <<     bitstream.format&.long_name || "Unknown File Format"
    html <<   "</p>"
    html <<   "<p>No preview is available for this file type.</p>"
    html << "</div>"
    raw(html.string)
  end

  def object_tag_for(bitstream)
    raw("<object data=\"#{bitstream.presigned_url(content_disposition: "inline")}\" "\
      "type=\"#{bitstream.media_type}\"></object>")
  end

  def text_viewer_for(bitstream)
    # Downloading the text and putting it in a <pre> makes it easier to style
    # than putting it in an <object>.
    data = bitstream.data
    html = StringIO.new
    html << "<div class=\"text-viewer\">"
    html <<   "<pre>"
    html <<     html_escape(data)
    html <<   "</pre>"
    html << "</div>"
    raw(html.string)
  end

  def video_tag_for(bitstream)
    html = StringIO.new
    html << "<video controls>"
    html <<   "<source src=\"#{bitstream.presigned_url}\" type=\"#{bitstream.media_type}\">"
    html <<   no_viewer_for(bitstream)
    html << "</video>"
    raw(html.string)
  end

end