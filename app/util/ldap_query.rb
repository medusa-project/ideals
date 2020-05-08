##
# This code forked from:
# https://github.com/medusa-project/kumquat/commit/69287f75fb0a0ae1c81c0fcb973f8ed16257624a#diff-2c420abceb4fab29f67b7c0d6e19c52a
#
class LdapQuery

  delegate :ldap_cache_key, to: :class

  def is_member_of?(group, net_id)
    return false unless group.present?
    json = Rails.cache.fetch(ldap_cache_key(net_id)) do
      "{}"
    end
    hash = JSON.parse(json)
    if hash.has_key?(group)
      hash[group]
    else
      uri          = URI.parse(ldap_url(group, net_id))
      http         = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      request      = Net::HTTP::Get.new(uri.request_uri)
      response     = http.request(request)
      if response.code.to_i < 300
        (response.body == "TRUE").tap do |is_member|
          hash[group] = is_member
          Rails.cache.write(ldap_cache_key(net_id), hash.to_json,
                            expires_in: 1.day,
                            race_condition_ttl: 10.seconds)
        end
      else
        # don't authenticate, but also don't cache, in this case
        false
      end
    end
  end

  def ldap_url(group, netid)
    group = group.gsub(" ", "%20") # URI.encode() does this but is deprecated
    "https://quest.library.illinois.edu/directory/ad/#{netid}/ismemberof/#{group}"
  end

  def self.ldap_cache_key(net_id)
    "ldap_#{net_id}"
  end

  def self.reset_cache(net_id = nil)
    Rails.cache.delete(ldap_cache_key(net_id))
  end

end
