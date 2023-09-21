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
  # @param key [String] Private key used to sign the certificate (optional).
  # @return [String] HTML <dl> element.
  #
  def x509_cert_as_card(cert:, key: nil)
    html    = StringIO.new
    cert    = OpenSSL::X509::Certificate.new(cert)
    invalid = key && !cert.check_private_key(OpenSSL::PKey::RSA.new(key))
    html << "<div class=\"card #{invalid ? "border-danger" : ""}\">"
    html <<   "<div class=\"card-body\">"
    if invalid
      html << "<div class=\"alert alert-danger\">"
      html <<   "This certificate was not signed by the current private key."
      html << "</div>"
    end
    html <<     "<dl style=\"word-break: break-all\">"
    html <<       "<dt>Signature Algorithm</dt>"
    html <<       "<dd>"
    html <<         cert.signature_algorithm
    if cert.signature_algorithm != "sha256WithRSAEncryption"
      html << boolean(false, style: :word, false_value: "INVALID")
    end
    html <<       "</dd>"
    html <<       "<dt>Subject</dt>"
    html <<       "<dd>"
    html <<         "<code>"
    html <<           cert.subject
    html <<         "</code>"
    html <<       "</dd>"
    html <<       "<dt>Issuer</dt>"
    html <<       "<dd>"
    html <<         "<code>"
    html <<           cert.issuer
    html <<         "</code>"
    html <<       "</dd>"
    html <<       "<dt>Not Before</dt>"
    html <<       "<dd>"
    html <<         local_time(cert.not_before)
    html <<       "</dd>"
    html <<       "<dt>Not After</dt>"
    html <<       "<dd>"
    html <<         local_time(cert.not_after)
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