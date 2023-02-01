module InstitutionsHelper

  # See https://stackoverflow.com/a/68189611
  FAVICONS = [
    # All browsers
    { rel: "icon", type: "image/png", size: 16 },
    { rel: "icon", type: "image/png", size: 32 },
    # Google and Android
    { rel: "icon", type: "image/png", size: 48 },
    { rel: "icon", type: "image/png", size: 192 },
    # iPad
    { rel: "apple-touch-icon", type: "image/png", size: 167 },
    # iPhone
    { rel: "apple-touch-icon", type: "image/png", size: 180 }
  ]

  ##
  # @return [String] HTML `link` tags.
  #
  def institution_favicon_tags
    if current_institution
      html = StringIO.new
      FAVICONS.each do |icon|
        html << raw("<link rel=\"#{icon[:rel]}\" "\
                    "type=\"#{icon[:type]}\" "\
                    "sizes=\"#{icon[:size]}x#{icon[:size]}\" "\
                    "href=\"#{current_institution.favicon_url(size: icon[:size])}\">\n")
      end
      raw(html.string)
    end
  end

end