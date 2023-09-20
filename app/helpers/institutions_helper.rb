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

  ##
  # @param cert [String]
  # @return [String] HTML <dl> element.
  #
  def x509_cert_as_card(cert)
    html = StringIO.new
    cert = OpenSSL::X509::Certificate.new(cert)
    html << "<div class=\"card\">"
    html <<   "<div class=\"card-body\">"
    html <<     "<dl>"
    html <<       "<dt>Signature Algorithm</dt>"
    html <<       "<dd>"
    html <<         cert.signature_algorithm
    if cert.signature_algorithm != "sha256WithRSAEncryption"
      html << boolean(false, style: :word, false_value: "INVALID")
    end
    html <<       "</dd>"
    html <<       "<dt>Subject</dt>"
    html <<       "<dd>"
    html <<         "<code style=\"word-break: break-all\">"
    html <<           cert.subject
    html <<         "</code>"
    html <<       "</dd>"
    html <<       "<dt>Issuer</dt>"
    html <<       "<dd>"
    html <<         "<code style=\"word-break: break-all\">"
    html <<           cert.issuer
    html <<         "</code>"
    html <<       "</dd>"
    html <<       "<dt>Issued</dt>"
    html <<       "<dd>"
    html <<         cert.not_before
    html <<       "</dd>"
    html <<       "<dt>Expires</dt>"
    html <<       "<dd>"
    html <<         cert.not_after
    html <<       "</dd>"
    html <<     "</dl>"
    html <<   "</div>"
    html << "</div>"
    raw(html.string)
  rescue
    html = boolean(false, style: :word, false_value: "INVALID")
    raw(html)
  end

end