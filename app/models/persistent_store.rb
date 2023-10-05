# frozen_string_literal: true

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
  MAX_UPLOAD_SIZE     = 2 ** 30 * 5 # 5 GB

  ##
  # @param source_key [String]
  # @param target_key [String]
  # @param public [Boolean] Whether the target object should have a public-read
  #                         ACL attached to it.
  #
  def copy_object(source_key:, target_key:, public: false)
    raise ArgumentError, "Source key is blank" if source_key.blank?
    raise ArgumentError, "Target key is blank" if target_key.blank?
    client = S3Client.instance
    client.copy_object(copy_source: "/#{BUCKET}/#{CGI.escape(source_key)}", # source bucket+key
                       bucket:      BUCKET,                     # destination bucket
                       key:         target_key)                 # destination key
    attach_public_acl(target_key) if public
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
  # @param source_key [String]
  # @param target_key [String]
  #
  def move_object(source_key:, target_key:)
    copy_object(source_key: source_key, target_key: target_key, public: false)
    delete_object(key: source_key)
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
  # @param expires_in [Integer] Seconds.
  # @param response_content_type [String]
  # @param response_content_disposition [String]
  # @return [String]
  # @see public_url
  #
  def presigned_download_url(key:,
                             expires_in:                   900,
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
  # @param key [String]          Target object key.
  # @param upload_id [String]    For multipart uploads.
  # @param part_number [Integer] For multipart uploads.
  # @param expires_in [Integer]  Seconds.
  # @return [String]
  # @see public_url
  #
  def presigned_upload_url(key:,
                           upload_id:   nil,
                           part_number: nil,
                           expires_in:  30)
    if (upload_id.present? && part_number.blank?) ||
      (upload_id.blank? && part_number.present?)
      raise ArgumentError, "upload_id and part_number must both be provided"
    end
    resource = S3Client.instance.send(:get_resource)
    bucket   = resource.bucket(BUCKET)
    object   = bucket.object(key)
    if upload_id && part_number
      object.presigned_url(:upload_part,
                           upload_id:   upload_id.to_s,
                           part_number: part_number,
                           expires_in:  expires_in)
    else
      object.presigned_url(:put, expires_in: expires_in)
    end
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
  # @param institution_key [String]        Optional--if not provided, it will
  #                                        be extracted from the key.
  # @param data [String]                   Raw data.
  # @param path [String]                   Pathname of a file to upload.
  # @param file [File, Pathname, Tempfile] File to upload.
  # @param io [IO]                         Stream to upload.
  # @param public [Boolean]                Whether the object should have a
  #                                        public-read ACL assigned to it.
  #
  def put_object(key:,
                 data:   nil,
                 path:   nil,
                 file:   nil,
                 io:     nil,
                 public: false)
    if !data && !path && !file && !io
      raise ArgumentError, "One of the source arguments must be provided."
    end
    acl = public ? "public-read" : "private"
    if path || file
      # N.B.: Aws::S3::Object.upload_file() will automatically use the
      # multipart API for files larger than 15 MB. (S3 has a 5 GB limit when
      # not using the multipart API.)
      s3 = Aws::S3::Resource.new(S3Client.client_options)
      s3.bucket(BUCKET).
        object(key).
        upload_file(path || file, acl: acl)
    else
      S3Client.instance.put_object(bucket:  BUCKET,
                                   key:     key,
                                   acl:     acl,
                                   body:    data || io)
    end
  end

  ##
  # Uploads every file in a directory tree to the application S3 bucket under
  # the given key prefix.
  #
  # @param root_path [String] Local root path.
  # @param key_prefix [String] Key prefix of uploaded objects.
  # @param uploaded_keys [Array<String>] Uploaded keys will be added to this
  #                                      array.
  #
  def upload_path(root_path:, key_prefix:, uploaded_keys: []) # TODO: rename to put_objects()
    raise IOError, "Not a directory: #{root_path}" unless File.directory?(root_path)
    key_prefix = key_prefix[0..-2] if key_prefix.end_with?("/")
    Dir.glob(root_path + "/**/*").select{ |p| File.file?(p) }.each do |path|
      key = key_prefix + path.gsub(root_path, "")
      put_object(key: key, path: path)
      uploaded_keys << key
    end
  end


  private

  def attach_public_acl(key)
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