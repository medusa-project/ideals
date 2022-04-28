class LdapQuery

  delegate :cache_key, to: :class

  CACHE_TTL = 12.hours

  ##
  # @param net_id [String]
  # @param group [AdGroup,String]
  # @return [Boolean]
  #
  def is_member_of?(net_id, group)
    group     = group.to_s
    cache_key = cache_key(net_id, group)
    json      = Rails.cache.fetch(cache_key) do
      "{}"
    end
    hash = JSON.parse(json)
    if hash.has_key?(cache_key)
      hash[cache_key]
    else
      uri              = URI.parse(ldap_url(net_id, group))
      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = (uri.scheme == "https")
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request          = Net::HTTP::Get.new(uri.request_uri)
      response         = http.request(request)
      if response.code.to_i < 300
        (response.body == 'TRUE').tap do |is_member|
          hash[cache_key] = is_member
          Rails.cache.write(cache_key(net_id, group),
                            hash.to_json,
                            expires_in:         CACHE_TTL,
                            race_condition_ttl: 10.seconds)
        end
      end
    end
  end


  private

  def ldap_url(net_id, group)
    sprintf("https://quest.library.illinois.edu/directory/ad/%s/ismemberof/%s",
            net_id,
            group.gsub(" ", "%20"))
  end

  def self.cache_key(net_id, group)
    "ldap_#{net_id}_#{group}"
  end

end
