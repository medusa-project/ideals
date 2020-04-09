##
# Convenience class used for obtaining and refreshing OAuth access tokens from
# Box and/or the session.
#
# # Usage
#
# If {access_token} returns a non-`nil` value, use it. Otherwise,
# obtain a new token via {new_access_token}.
#
class BoxClient

  ##
  # @param callback_url [String] URL to redirect to.
  # @param return_url [String] Information to add to  the `state` argument.
  # @return [String]
  #
  def self.authorization_url(callback_url:, state:)
    config = ::Configuration.instance
    "https://account.box.com/api/oauth2/authorize?response_type=code" +
        "&client_id=#{config.box[:client_id]}" +
        "&redirect_url=#{callback_url}" +
        "&state=#{state}"
  end

  def initialize(session)
    @session = session
  end

  ##
  # Fetches the access token from the session. If the token is expired, it is
  # refreshed, stored, and returned. If there is no token in the session, `nil`
  # is returned.
  #
  # @return [Hash] Hash with the same structure as the one returned from
  #                {new_access_token}.
  #
  def access_token
    if @session['box'].present?
      if Time.now > @session['box']['expires']
        token = refresh_access_token(@session['box']['refresh_token'])
        @session['box'] = token
        return token
      else
        return @session['box']
      end
    end
    nil
  end

  ##
  # Exchanges the OAuth access code (supplied as a query argument to the OAuth
  # callback URL) for an access token, stores it in the session, and returns
  # it.
  #
  # @param code [String]
  # @return [Hash] Hash with `:access_token`, `:expires`, and `:refresh_token`
  #                keys.
  # @see https://developer.box.com/reference/post-oauth2-token/
  #
  def new_access_token(code)
    config = ::Configuration.instance
    body   = {
        client_id:     config.box[:client_id],
        client_secret: config.box[:client_secret],
        code:          code,
        grant_type:    "authorization_code"
    }
    response       = post("https://account.box.com/api/oauth2/token", body)
    token          = token_from_response(response.body)
    @session['box'] = token
    token
  end

  private

  def post(url, body)
    headers = { 'Content-Type': "application/x-www-form-urlencoded" }
    HTTPClient.new.post(url, body, headers)
  end

  ##
  # @param refresh_token [String]
  #
  def refresh_access_token(refresh_token)
    config = ::Configuration.instance
    body   = {
        client_id:     config.box[:client_id],
        client_secret: config.box[:client_secret],
        refresh_token: refresh_token,
        grant_type:    "refresh_token"
    }
    response = post("https://api.box.com/oauth2/token", body)
    token_from_response(response.body)
  end

  ##
  # @param entity [String] HTTP response entity a.k.a. body.
  # @return [Hash] Hash with `:access_token`, `:expires`, and `:refresh_token`
  #                keys.
  #
  def token_from_response(entity)
    struct = JSON.parse(entity)
    {
        access_token:  struct['access_token'],
        expires:       Time.now + struct['expires_in'],
        refresh_token: struct['refresh_token']
    }
  end

end