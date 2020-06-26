##
# @see https://wiki.illinois.edu/wiki/display/scrs/Handle+Server
# @see http://hdl.handle.net/20.1000/113
#
class HandleClient

  ##
  # @param handle [String]
  # @param url [String] Destination URL.
  # @return [void]
  #
  def create_url_handle(handle, url)
    value = JSON.generate({
        handle: handle,
        values: [
            {
                index: 100,
                type: "HS_ADMIN",
                data: {
                    format: "admin",
                    value: {
                        handle: "0.NA/#{prefix}",
                        index: 200,
                        permissions: "110011111111"
                   }
                }
            },
            {
                index: 1,
                type: "URL",
                data: {
                    format: "string",
                    value: url
                },
                ttl: 86400,
                timestamp: Time.now.utc.iso8601
            }
        ]
    })
    response = client.put("#{api_endpoint}/handles/#{handle}", value,
                          'Content-Type': "application/json")
    struct = JSON.parse(response.body)
    handle_response(struct, "message")
  end

  ##
  # @param handle [String]
  # @return [void]
  #
  def delete_handle(handle)
    response = client.delete("#{api_endpoint}/handles/#{handle}")
    struct = JSON.parse(response.body)
    handle_response(struct, "message")
  end

  ##
  # @param handle [String]
  # @return [Enumerable<Hash>,nil] Handle structure, or nil if the handle does
  #         not exist.
  # @raises [IOError]
  #
  def get_handle(handle)
    response = client.get("#{api_endpoint}/handles/#{handle}")
    struct = JSON.parse(response.body)
    handle_response(struct, "values")
  end

  def get_handles(prefix)
    response = client.get("#{api_endpoint}/handles?prefix=#{prefix}")
    struct = JSON.parse(response.body)
    handle_response(struct, "handles")
  end

  private

  def api_endpoint
    ::Configuration.instance.handles[:api][:endpoint].chomp("/")
  end

  def api_secret
    ::Configuration.instance.handles[:api][:basic_secret]
  end

  def api_user
    ::Configuration.instance.handles[:api][:basic_user]
  end

  def prefix
    ::Configuration.instance.handles[:prefix]
  end

  def client
    unless @client
      endpoint = api_endpoint
      user     = api_user.gsub(":", "%3A")
      secret   = api_secret
      @client = HTTPClient.new do
        self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.force_basic_auth = true
        uri    = URI.parse(endpoint)
        domain = "#{uri.scheme}://#{uri.host}:#{uri.port}"
        self.set_auth(domain, user, secret)
      end
    end
    @client
  end

  def handle_response(struct, success_key)
    case struct['responseCode']
    when 1
      return struct[success_key]
    when 100
      return nil
    when 402
      raise IOError, "Unauthorized"
    else
      raise IOError, struct['message']
    end
  end

end
