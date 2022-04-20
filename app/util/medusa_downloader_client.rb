##
# Client for downloading item content via the
# [Medusa Downloader](https://github.com/medusa-project/medusa-downloader).
#
# This class was forked from [the same one in Kumquat]
# (https://github.com/medusa-project/kumquat/blob/develop/app/medusa/medusa_downloader_client.rb)
#
class MedusaDownloaderClient

  LOGGER               = CustomLogger.new(MedusaDownloaderClient)
  CREATE_DOWNLOAD_PATH = '/downloads/create'

  ##
  # @param request_context [RequestContext]
  #
  def initialize(request_context: nil)
    @request_context = request_context
  end

  ##
  # Sends a request to the Downloader to generate a zip file for the given
  # item, and returns its URL.
  #
  # @param item [Item]
  # @param user [User]
  # @return [String] Download URL to which clients can be redirected.
  # @raises [ArgumentError] If illegal arguments have been supplied.
  # @raises [IOError] If there is an error communicating with the Downloader.
  #
  def download_url(item:, user: nil)
    raise ArgumentError, "Item is nil" if item.nil?
    # Compile the list of items to include in the file.
    targets = targets_for(item, user: user)
    if targets.empty?
      raise ArgumentError, "This item either has no files to download, or "\
          "you are not authorized to download any of them."
    end

    # Prepare the initial request.
    config  = ::Configuration.instance
    url     = "#{config.downloader[:base_url]}/#{CREATE_DOWNLOAD_PATH}"
    headers = { 'Content-Type': "application/json" }
    body    = JSON.generate(
      root:     "medusa",
      zip_name: "item_#{item.id}",
      targets:  targets)

    LOGGER.debug("download_url(): requesting %s", body)
    response = client.post(url, body, headers)

    # Ideally this would be 200, but HTTPClient's digest auth doesn't seem to
    # work as of 2.8.3, so it's more likely 401 so we'll have to do the digest
    # auth flow manually.
    if response.status == 401
      headers['Authorization'] =
        digest_auth_header(response.headers['WWW-Authenticate'])
      LOGGER.debug("download_url(): retrying %s", body)
      response = client.post(url, body, headers)
    end

    response_hash = JSON.parse(response.body)
    if response.status > 299
      LOGGER.error("download_url(): received HTTP %d: %s",
                   response.status, response.body)
      raise IOError, response_hash['error']
    end
    response_hash['download_url']
  end

  ##
  # Issues an HTTP HEAD request to check whether the server is up.
  #
  # @raises [IOError] If the server does not respond as expected.
  #
  def head
    config   = ::Configuration.instance
    response = client.head(config.downloader[:base_url])
    raise IOError, response.status if response.status != 200
  end


  private

  def client
    unless @client
      config = ::Configuration.instance
      url    = config.downloader[:base_url]
      @client = HTTPClient.new do
        self.ssl_config.cert_store.set_default_paths
        self.receive_timeout = 10000
        uri     = URI.parse(url)
        domain  = uri.scheme + '://' + uri.host
        domain += ":#{uri.port}" unless [80, 443].include?(uri.port)
        user    = config.downloader[:username]
        secret  = config.downloader[:secret]
        self.set_auth(domain, user, secret)
      end
    end
    @client
  end

  ##
  # @param www_authenticate_header [String] `WWW-Authenticate` response header
  #                                         value.
  # @return [String] Value to use in an `Authorization` header.
  #
  def digest_auth_header(www_authenticate_header)
    config                = ::Configuration.instance
    auth_info             = parse_auth_header(www_authenticate_header)
    auth_info['username'] = config.downloader[:username]
    auth_info['uri']      = CREATE_DOWNLOAD_PATH
    auth_info['nc']       = '00000001'
    auth_info['cnonce']   = SecureRandom.hex

    ha1 = Digest('MD5').hexdigest(sprintf('%s:%s:%s',
                                          config.downloader[:username],
                                          auth_info['realm'],
                                          config.downloader[:secret]))
    ha2 = Digest('MD5').hexdigest("POST:#{CREATE_DOWNLOAD_PATH}")
    auth_info['response'] = Digest('MD5').hexdigest(sprintf('%s:%s:%s:%s:%s:%s',
                                                            ha1,
                                                            auth_info['nonce'],
                                                            auth_info['nc'],
                                                            auth_info['cnonce'],
                                                            auth_info['qop'],
                                                            ha2))
    "Digest #{auth_info.map{ |k,v| "#{k}=\"#{v}\"" }.join(', ')}"
  end

  ##
  # @param header [String]
  # @return [Hash]
  #
  def parse_auth_header(header)
    auth_info = {}
    matches   = header.scan(/([a-zA-Z]+)="([^"]+)",?/)
    matches.each do |match|
      auth_info[match[0]] = match[1]
    end
    auth_info
  end

  ##
  # @param item [Item]
  # @param user [User]
  # @return [Enumerable<Hash>]
  #
  def targets_for(item, user: nil)
    targets = []
    item.bitstreams.each do |bs|
      bs.add_download(user: user)
      if @request_context.nil? || BitstreamPolicy.new(@request_context, bs).download?
        targets << { type: "file", path: bs.medusa_key }
      end
    end
    targets
  end

end