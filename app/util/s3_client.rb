##
# Wraps an {Aws::S3::Client}, adding some convenience methods and forwarding
# all other method calls to it.
#
# N.B.: there is a higher-level interface to the application S3 bucket in
# {PersistentStore}. It is recommended to use that instead where possible--
# especially when writing to the bucket.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
# @see PersistentStore
#
class S3Client

  include Singleton

  def self.client_options
    config = ::Configuration.instance
    opts   = { region: config.storage[:region] }
    if Rails.env.development? || Rails.env.test?
      # In development and test, we connect to a custom endpoint, and
      # credentials are drawn from the application configuration.
      opts[:endpoint]         = config.storage[:endpoint]
      opts[:force_path_style] = true
      opts[:credentials]      = Aws::Credentials.new(config.storage[:access_key_id],
                                                     config.storage[:secret_access_key])
    end
    opts
  end

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

  def delete_objects(bucket:, key_prefix: "")
    bucket = get_resource.bucket(bucket)
    bucket.objects(prefix: key_prefix).each(&:delete)
  end

  def method_missing(m, *args, &block)
    if get_client.respond_to?(m)
      get_client.send(m, *args, &block)
    else
      super
    end
  end

  def num_objects(bucket:, key_prefix:)
    objects(bucket: bucket, key_prefix: key_prefix).count
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

  def objects(bucket:, key_prefix:)
    bucket = get_resource.bucket(bucket)
    bucket.objects(prefix: key_prefix)
  end


  private

  def get_client
    @client = Aws::S3::Client.new(self.class.client_options) unless @client
    @client
  end

  def get_resource
    @resource = Aws::S3::Resource.new(self.class.client_options) unless @resource
    @resource
  end

end