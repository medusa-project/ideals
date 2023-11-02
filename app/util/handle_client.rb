# frozen_string_literal: true

##
# @see https://wiki.illinois.edu/wiki/display/scrs/Handle+Server
# @see https://hdl.handle.net/20.1000/113
#
class HandleClient

  LOGGER = CustomLogger.new(HandleClient)

  ##
  # @param handle [String]
  # @param url [String] Destination URL.
  # @return [void]
  #
  def create_url_handle(handle:, url:)
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
    handle_url = "#{api_endpoint}/handles/#{handle}"
    LOGGER.debug("create_url_handle(): #{handle_url} -> #{url}")
    response = client.put(handle_url, value, 'Content-Type': "application/json")
    handle_response("PUT", handle_url, response)
  end

  ##
  # @param handle [String]
  # @return [void]
  #
  def delete_handle(handle)
    handle_url = "#{api_endpoint}/handles/#{handle}"
    LOGGER.debug("delete_handle(): #{handle_url}")
    response = client.delete(handle_url)
    handle_response("DELETE", handle_url, response)
  end

  ##
  # @param handle [String]
  # @return [Boolean]
  #
  def exists?(handle)
    url = "#{api_endpoint}/handles/#{handle}"
    response = client.head(url)
    response.status < 300
  end

  ##
  # @param handle [String]
  # @return [Enumerable<Hash>,nil] Handle structure, or nil if the handle does
  #         not exist.
  # @raises [IOError]
  #
  def get_handle(handle)
    url = "#{api_endpoint}/handles/#{handle}"
    response = client.get(url)
    if response.status >= 400
      if response.status == 404
        return nil
      else
        raise IOError, "Got HTTP #{response.status} for GET #{url}"
      end
    end
    struct = JSON.parse(response.body)
    struct['values']
  end

  ##
  # @return [Enumerable<String>]
  #
  def get_handles
    url      = "#{api_endpoint}/handles?prefix=#{prefix}"
    response = client.get(url)
    handle_response("GET", url, response)
    struct   = JSON.parse(response.body)
    struct['handles']
  end

  ##
  # @return [String]
  #
  def list_prefixes
    url      = "#{api_endpoint}/prefixes"
    response = client.get(url)
    handle_response("GET", url, response)
    struct   = JSON.parse(response.body)
    struct['prefixes']
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
        # The server cert is self-signed.
        self.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.force_basic_auth = true
        uri    = URI.parse(endpoint)
        domain = "#{uri.scheme}://#{uri.host}:#{uri.port}"
        self.set_auth(domain, user, secret)
      end
    end
    @client
  end

  def handle_response(method, url, response)
    if response.status >= 400 && response.status != 404
      raise IOError, "Got HTTP #{response.status} for #{method} #{url}: #{response.body}"
    end
    nil
  end

end
