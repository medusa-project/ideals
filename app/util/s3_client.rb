##
# Wraps an {Aws::S3::Client}, adding some convenience methods and forwarding
# all other method calls to it.
#
# @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html
#
class S3Client

  include Singleton

  def self.client_options
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

  ##
  # Uploads every file in a directory tree to a bucket under the given key
  # prefix.
  #
  # @param root_path [String] Root path on the file system.
  # @param bucket [String] Bucket to upload to.
  # @param key_prefix [String] Key prefix of uploaded objects.
  #
  def upload_path(root_path:, bucket:, key_prefix:)
    key_prefix = key_prefix[0..-2] if key_prefix.end_with?("/")
    Dir.glob(root_path + "/**/*").select{ |p| File.file?(p) }.each do |path|
      rel_path = path.gsub(root_path, "")
      S3Client.instance.put_object(bucket: bucket,
                                   key:    key_prefix + rel_path,
                                   body:   File.read(path))
    end
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