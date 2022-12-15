##
# High-level interface to the application's persistent store (currently an S3
# bucket). It is recommended to use this class instead of {S3Client} especially
# when writing to the bucket, to ensure that the resulting objects receive the
# correct tags, ACLs, metadata, etc.
#
class PersistentStore

  include Singleton

  BUCKET              = ::Configuration.instance.storage[:bucket]
  INSTITUTION_KEY_TAG = "institution_key"

  ##
  # @param source_key [String]
  # @param target_key [String]
  #
  def copy_object(source_key:, target_key:)
    client = S3Client.instance
    client.copy_object(copy_source: "/#{BUCKET}/#{source_key}", # source bucket+key
                       bucket:      BUCKET,                     # destination bucket
                       key:         target_key)                 # destination key
    update_acl(target_key)
  end

  ##
  # @param key [String]
  #
  def delete_object(key:)
    S3Client.instance.delete_object(bucket: BUCKET, key: key)
  end

  ##
  # @param key_prefix [String]
  #
  def delete_objects(key_prefix:)
    S3Client.instance.delete_objects(bucket: BUCKET, key_prefix: key_prefix)
  end

  ##
  # @param key [String]
  # @return [IO]
  #
  def get_object(key:, response_target: nil)
    S3Client.instance.get_object(bucket:          BUCKET,
                                 key:             key,
                                 response_target: response_target).body
  end

  ##
  # @param key_prefix [String]
  # @return [Integer]
  #
  def object_count(key_prefix:)
    count = 0
    objects(key_prefix: key_prefix).each{ count += 1 }
    count
  end

  ##
  # @param key [String]
  # @return [Boolean]
  #
  def object_exists?(key:)
    S3Client.instance.object_exists?(bucket: BUCKET, key: key)
  end

  ##
  # @param key [String]
  # @return [IO]
  #
  def object_length(key:)
    S3Client.instance.head_object(bucket: BUCKET, key: key).content_length
  end

  ##
  # @param key_prefix [String]
  # @return [Enumerable<Aws::S3::Object>]
  #
  def objects(key_prefix:)
    S3Client.instance.objects(bucket: BUCKET, key_prefix: key_prefix)
  end

  ##
  # @param key [String]
  # @param expires_in [Integer]
  # @param response_content_type [String]
  # @param response_content_disposition [String]
  # @return [String]
  # @see public_url
  #
  def presigned_url(key:,
                    expires_in:,
                    response_content_type:        nil,
                    response_content_disposition: nil)
    aws_client = S3Client.instance.send(:get_client)
    signer     = Aws::S3::Presigner.new(client: aws_client)
    signer.presigned_url(:get_object,
                         bucket:                       BUCKET,
                         key:                          key,
                         expires_in:                   expires_in,
                         response_content_type:        response_content_type,
                         response_content_disposition: response_content_disposition)
  end

  ##
  # @param key [String]
  # @return [String] Non-presigned public object URL. (The object must of
  #                  course be public for this to work.)
  # @see presigned_url
  #
  def public_url(key:)
    s3 = Aws::S3::Resource.new(S3Client.client_options)
    s3.bucket(BUCKET).object(key).public_url
  end

  ##
  # @param key [String]
  # @param institution_key [String] Optional--if not provided, it will be
  #                                 extracted from the key.
  # @param data [String] Raw data.
  # @param path [String] Pathname of a file to upload.
  # @param file [File, Pathname, Tempfile] File to upload.
  # @param io [IO] Stream to upload.
  #
  def put_object(key:,
                 institution_key: nil,
                 data:            nil,
                 path:            nil,
                 file:            nil,
                 io:              nil)
    if !data && !path && !file && !io
      raise ArgumentError, "One of the source arguments must be provided."
    end
    unless institution_key
      result = key.match(/^institutions\/(\w+)/i)
      institution_key = result.captures[0] if result
    end
    if institution_key
      tags = {}
      tags[INSTITUTION_KEY_TAG] = institution_key
      tagging = tags.map{ |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    else
      tagging = nil
    end

    if path || file
      # N.B.: Aws::S3::Object.upload_file() will automatically use the
      # multipart API for files larger than 15 MB. (S3 has a 5 GB limit when
      # not using the multipart API.)
      s3 = Aws::S3::Resource.new(S3Client.client_options)
      s3.bucket(BUCKET).
        object(key).
        upload_file(path || file)
      update_acl(key)
      if institution_key
        S3Client.instance.set_tag(bucket:    BUCKET,
                                  key:       key,
                                  tag_key:   INSTITUTION_KEY_TAG,
                                  tag_value: institution_key)
      end
    else
      S3Client.instance.put_object(bucket:  BUCKET,
                                   key:     key,
                                   acl:     "public-read",
                                   body:    data || io,
                                   tagging: tagging)
    end
  end

  ##
  # Uploads every file in a directory tree to the application S3 bucket under
  # the given key prefix.
  #
  # @param root_path [String] Root path on the file system.
  # @param key_prefix [String] Key prefix of uploaded objects.
  #
  def upload_path(root_path:, key_prefix:)
    key_prefix = key_prefix[0..-2] if key_prefix.end_with?("/")
    Dir.glob(root_path + "/**/*").select{ |p| File.file?(p) }.each do |path|
      rel_path = path.gsub(root_path, "")
      put_object(key: key_prefix + rel_path, path: path)
    end
  end


  private

  def update_acl(key)
    # MinIO (used in development & test) doesn't support ACLs
    unless Rails.env.development? || Rails.env.test?
      S3Client.instance.put_object_acl(
        acl:    "public-read",
        bucket: BUCKET,
        key:    key
      )
    end
  end

end