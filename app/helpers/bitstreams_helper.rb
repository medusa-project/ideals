# frozen_string_literal: true

module BitstreamsHelper

  ##
  # Returns an `img` tag for the given bitstream. If the bitstream
  # {Bitstream#has_representative_image? has a representative image}, that is
  # used. Otherwise, an appropriate generic icon is chosen based on the
  # {FileFormat} registry.
  #
  # @param bitstream [Bitstream]
  # @param region [Symbol] See {Bitstream#derivative_image_url}.
  # @param size [Integer] See {Bitstream#derivative_image_url}. This is the
  #                       literal size of the image; the `img` tag has no
  #                       `width` or `height` attribute and must be sized via
  #                       CSS.
  # @param generate_async [Boolean]
  # @param attrs [Hash] Additional tag attributes.
  # @return [String] HTML `img` tag.
  #
  def representative_image_tag(bitstream,
                               region: :full,
                               size:,
                               generate_async: false,
                               **attrs)
    path = nil
    if bitstream.has_representative_image?
      begin
        path = bitstream.derivative_image_url(region:         region,
                                              size:           size,
                                              generate_async: generate_async)
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
    if format.present?
      method = format.viewer_method
      if method.present?
        return send(method, bitstream)
      end
    end
    no_viewer_for(bitstream)
  end


  private

  def audio_tag_for(bitstream)
    html = StringIO.new
    html << "<audio controls>"
    html <<   "<source src=\"#{bitstream.presigned_download_url}\" type=\"#{bitstream.media_type}\">"
    html <<   no_viewer_for(bitstream)
    html << "</audio>"
    raw(html.string)
  end

  ##
  # @param bitstream [Bitstream]
  #
  def html_viewer_for(bitstream)
    # We have to use /data rather than /object because of the Same Origin
    # restriction (we will need to access the contents of the iframe using JS).
    src = item_bitstream_data_path(bitstream.item, bitstream,
                                   "response-content-disposition": "inline")
    raw("<iframe src=\"#{src}\" "\
          "title=\"Embedded HTML file: #{StringUtils.sanitize_filename(bitstream.filename)}\" "\
          "style=\"background:white; border:none; height:100%; width:100%;\" "\
          "sandbox=\"allow-same-origin allow-scripts allow-top-navigation\"></iframe>")
  end

  def image_tag_for(bitstream)
    representative_image_tag(bitstream, size: 2048)
  end

  def no_viewer_for(bitstream, message: nil)
    message ||= "No preview is available for this file type."
    html = StringIO.new
    html << "<div class=\"unsupported-format\">"
    html <<   "<p class=\"format-name\">"
    html <<     bitstream.format&.long_name || "Unknown File Format"
    html <<   "</p>"
    html <<   "<p>#{message}</p>"
    html << "</div>"
    raw(html.string)
  end

  def object_tag_for(bitstream)
    raw("<object data=\"#{bitstream.presigned_download_url(content_disposition: "inline")}\" "\
      "type=\"#{bitstream.media_type}\"></object>")
  end

  ##
  # Renders a PDF in an `<object>` tag if the browser natively supports PDFs,
  # falling back PDF.js otherwise. This is currently not used because testing
  # has revealed weird behavior in several browsers (including Firefox and
  # Safari but not Chrome) where PDFs sometimes load and sometimes don't, or in
  # Safari's case, the first page appears but the rest of the pages appear
  # blank.
  #
  def pdf_object_viewer_for(bitstream)
    html = StringIO.new
    # This container will contain two different viewers: PDF.js and a native
    # viewer. One or the other will be shown via JS depending on whether the
    # browser already supports PDF.

    # Add a PDF.js viewer
    html << pdfjs_viewer_for(bitstream)

    # Add a generic embedded viewer; this is preferable to PDF.js when
    # the browser supports embedded PDFs
    bitstream_path = bitstream.presigned_download_url(content_disposition: "inline")
    html          << "<object id=\"native-pdf-viewer\" "\
                         "data=\"#{bitstream_path}\" "\
                         "type=\"#{bitstream.media_type}\"></object>"

    raw(html.string)
  end

  ##
  # @see pdf_object_viewer_for
  #
  def pdfjs_viewer_for(bitstream)
    # N.B.: the PDF.js source code must be modified to allow it to use
    # cross-domain requests. See: https://stackoverflow.com/a/69342595
    # The commit history of public/pdfjs/web/viewer.js should reveal the
    # change.
    if bitstream.format.derivative_generator == "libreoffice"
      bitstream_url = item_bitstream_url(bitstream.item, bitstream, format: :pdf)
    else
      bitstream_url = bitstream.presigned_download_url(content_disposition: "inline")
    end
    viewer_url    = asset_path("/pdfjs/web/viewer.html?file=" + CGI.escape(bitstream_url))
    html          = "<iframe src=\"#{viewer_url}\" id=\"pdfjs-pdf-viewer\" "\
                            "height=\"100%\" width=\"100%\" "\
                            "frameborder=\"0\"></iframe>"
    raw(html)
  end

  ##
  # @param bitstream [Bitstream,String]
  #
  def text_viewer_for(bitstream)
    # Some huge text files cause web browsers to hang. So we will set a cutoff
    # size.
    if bitstream.kind_of?(Bitstream) && bitstream.length > 2.pow(22) # 4 MB
      return no_viewer_for(bitstream,
                           message: "This file is too large to preview, but "\
                                    "you may download it using the button above.")
    end
    # Downloading the text and putting it in a <pre> makes it easier to style
    # than putting it in an <object>.
    text = bitstream.kind_of?(Bitstream) ? bitstream.data.read : bitstream
    html = StringIO.new
    html << "<div class=\"text-viewer\">"
    html <<   "<pre>"
    html <<     html_escape(text)
    html <<   "</pre>"
    html << "</div>"
    raw(html.string)
  end

  def video_tag_for(bitstream)
    html = StringIO.new
    html << "<video controls>"
    html <<   "<source src=\"#{bitstream.presigned_download_url}\" type=\"#{bitstream.media_type}\">"
    html <<   no_viewer_for(bitstream)
    html << "</video>"
    raw(html.string)
  end

  def xml_viewer_for(bitstream)
    doc = Nokogiri::XML(bitstream.data.read, &:noblanks)
    xml = doc.to_xml(indent: 4, indent_text: " ")
    text_viewer_for(xml)
  end

end