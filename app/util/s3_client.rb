##
# Wraps an {Aws::S3::Client}, adding some convenience methods and forwarding
# all other method calls to it.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
#
class S3Client

  include Singleton

  ##
  # @param bucket [String]
  # @return [Boolean]
  #
  def bucket_exists?(bucket)
    begin
      get_client.head_bucket(bucket: bucket)
    rescue Aws::S3::Errors::NotFound
      return false
    else
      return true
    end
  end

  def method_missing(m, *args, &block)
    if get_client.respond_to?(m)
      get_client.send(m, *args, &block)
    else
      super
    end
  end

  ##
  # @param bucket [String]
  # @param key [String]
  # @return [Boolean]
  #
  def object_exists?(bucket:, key:)
    begin
      get_client.head_object(bucket: bucket, key: key)
    rescue Aws::S3::Errors::NotFound
      return false
    else
      return true
    end
  end

  private

  def get_client
    unless @client
      config = ::Configuration.instance
      opts   = { region: config.aws[:region] }
      if Rails.env.development? || Rails.env.test?
        # In development and test, we connect to a custom endpoint, and
        # credentials are drawn from the application configuration.
        opts[:endpoint]         = config.aws[:endpoint]
        opts[:force_path_style] = true
        opts[:credentials]      = Aws::Credentials.new(config.aws[:access_key_id],
                                                       config.aws[:secret_access_key])
      end
      @client = Aws::S3::Client.new(opts)
    end
    @client
  end

end