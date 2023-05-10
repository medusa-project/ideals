# frozen_string_literal: true

##
# The root of the main entity tree. All {Unit}s reside directly in an
# institution.
#
# Each institution has its own domain name at which its own website, scoped to
# its own content, is available. It may also use its own authentication system.
#
# # Attributes
#
# * `active_link_color`               Theme active hyperlink color.
# * `author_element_id`               Foreign key to {RegisteredElement}
#                                     designating an element to treat as the
#                                     author element.
# * `banner_image_filename`           Filename of the banner image, which may
#                                     exist in the application S3 bucket under
#                                     {image_key_prefix}. If not present, a
#                                     generic image is used.
# * `banner_image_height`             Height of the banner image.
# * `copyright_notice`                Generic institution-wide copyright
#                                     notice, generally displayed on the
#                                     website somewhere.
# * `created_at`                      Managed by ActiveRecord.
# * `date_approved_element_id`        Foreign key to {RegisteredElement}
#                                     designating an element to treat as the
#                                     date-approved element.
# * `date_published_element_id`       Foreign key to {RegisteredElement}
#                                     designating an element to treat as the
#                                     date-approved element.
# * `date_submitted_element_id`       Foreign key to {RegisteredElement}
#                                     designating an element to treat as the
#                                     date-submitted element.
# * `description_element_id`          Foreign key to {RegisteredElement}
#                                     designating an element to treat as the
#                                     description element.
# * `earliest_search_year`            Earliest year available in advanced
#                                     search.
# * `feedback_email`                  Email address for public feedback.
# * `footer_background_color`         Theme background color of the footer.
# * `footer_image_filename`           Filename of the footer image, which is
#                                     expected to exist in the application S3
#                                     bucket under {image_key_prefix}.
# * `handle_uri_element_id`           Foreign key to {RegisteredElement}
#                                     designating an element to treat as the
#                                     date-submitted element.
# * `has_favicon`                     Whether the instance has a favicon, i.e.
#                                     whether an institution admin has uploaded
#                                     one. Unlike the other image-related
#                                     attributes, the favicon's filenames are
#                                     fixed.
# * `header_background_color`         Theme background color of the header.
# * `header_image_filename`           Filename of the header image, which is
#                                     expected to exist in the application S3
#                                     bucket under {image_key_prefix}.
# * `key`                             Short string that uniquely and
#                                     permanently identifies the institution.
# * `latitude_degrees`                Degrees component of the institution's
#                                     latitude.
# * `latitude_minutes`                Minutes component of the institution's
#                                     latitude.
# * `latitude_seconds`                Seconds component of the institution's
#                                     latitude.
# * `link_color`                      Theme hyperlink color.
# * `link_hover_color`                Theme hover-over-hyperlink color.
# * `longitude_degrees`               The degrees component of the institution's
#                                     longitude.
# * `longitude_minutes`               The minutes component of the institution's
#                                     longitude.
# * `longitude_seconds`               The seconds component of the institution's
#                                     longitude.
# * `main_website_url`                URL of the institution's main website.
# * `medusa_file_group_id`            ID of the Medusa file group in which the
#                                     institution's content is stored.
# * `name`                            Institution name.
# * `openathens_email_attribute`      Required only by institutions that use
#                                     OpenAthens for authentication.
# * `openathens_first_name_attribute` Required only by institutions that use
#                                     OpenAthens for authentication.
# * `openathens_last_name_attribute`  Required only by institutions that use
#                                     OpenAthens for authentication.
# * `openathens_email_attribute`      Required only by institutions that use
#                                     OpenAthens for authentication.
# * `openathens_idp_cert`             Required only by institutions that use
#                                     OpenAthens for authentication.
# * `openathens_idp_sso_service_url`  Required only by institutions that use
#                                     OpenAthens for authentication.
# * `openathens_sp_entity_id`         Required only by institutions that use
#                                     OpenAthens for authentication.
# * `primary_color`                   Theme primary color.
# * `primary_hover_color`             Theme hover-over primary color.
# * `service_name`                    Name of the service that the institution
#                                     is running. For example, at UIUC, this
#                                     would be IDEALS.
# * `shibboleth_org_dn`               Value of an `eduPersonOrgDN` attribute
#                                     from the Shibboleth IdP. This should be
#                                     filled in by all institutions that use
#                                     Shibboleth for authentication (currently
#                                     only UIUC).
# * `title_element_id`                Foreign key to {RegisteredElement}
#                                     designating an element to treat as the
#                                     title element.
# * `updated_at`                      Managed by ActiveRecord.
# * `welcome_html`                    HTML text that appears on the main page.
#
class Institution < ApplicationRecord

  include Breadcrumb

  belongs_to :author_element, class_name: "RegisteredElement",
             foreign_key: :author_element_id, optional: true
  belongs_to :date_approved_element, class_name: "RegisteredElement",
             foreign_key: :date_approved_element_id, optional: true
  belongs_to :date_published_element, class_name: "RegisteredElement",
             foreign_key: :date_published_element_id, optional: true
  belongs_to :date_submitted_element, class_name: "RegisteredElement",
             foreign_key: :date_submitted_element_id, optional: true
  belongs_to :description_element, class_name: "RegisteredElement",
             foreign_key: :description_element_id, optional: true
  belongs_to :handle_uri_element, class_name: "RegisteredElement",
             foreign_key: :handle_uri_element_id, optional: true
  belongs_to :title_element, class_name: "RegisteredElement",
             foreign_key: :title_element_id, optional: true

  has_many :administrators, class_name: "InstitutionAdministrator"
  has_many :administering_users, through: :administrators,
           class_name: "User", source: :user
  has_many :administrator_groups, class_name: "InstitutionAdministratorGroup"
  has_many :administering_groups, through: :administrator_groups,
           class_name: "UserGroup", source: :user_group
  has_many :downloads
  has_many :imports
  has_many :index_pages
  has_many :invitees
  has_many :messages
  has_many :metadata_profiles
  has_many :prebuilt_searches
  has_many :registered_elements
  has_many :submission_profiles
  has_many :tasks
  has_many :units
  has_many :user_groups
  has_many :users
  has_many :vocabularies

  validates :feedback_email, allow_blank: true, length: {maximum: 255},
            format: {with: StringUtils::EMAIL_REGEX}

  # uniqueness enforced by database constraints
  validates :fqdn, presence: true

  # uniqueness enforced by database constraints
  validates :medusa_file_group_id, allow_nil: true,
            numericality: { only_integer: true }

  validates :active_link_color, presence: true
  validates :footer_background_color, presence: true
  validates :header_background_color, presence: true
  validates_format_of :key, with: /\A[A-Za-z0-9]+\Z/, allow_blank: false
  validates :latitude_degrees,
            numericality: { greater_than: 36, less_than: 43 }, # Illinois state bounds
            allow_blank: true
  validates :link_color, presence: true
  validates :link_hover_color, presence: true
  validates :longitude_degrees,
            numericality: { greater_than: -92, less_than: -87 }, # Illinois state bounds
            allow_blank: true
  validates :name, presence: true
  validates :primary_color, presence: true
  validates :primary_hover_color, presence: true
  validates :service_name, presence: true

  validate :disallow_key_changes, :validate_css_colors,
           :validate_authentication_method

  # N.B.: order is important!
  after_create :add_default_vocabularies, :add_default_elements,
               :add_default_element_mappings, :add_default_metadata_profile,
               :add_default_submission_profile, :add_default_index_pages,
               :add_default_user_groups

  ##
  # @param extension [String]
  # @return [String]
  #
  def self.banner_image_filename(extension)
    "banner.#{extension.gsub(".", "")}"
  end

  ##
  # @param institution_key [String]
  # @param extension [String] Filename extension.
  # @return [String]
  #
  def self.banner_image_key(institution_key, extension)
    [image_key_prefix(institution_key),
     banner_image_filename(extension)].join
  end

  ##
  # @param size [Integer]
  # @return [String]
  #
  def self.favicon_filename(size:)
    "favicon-#{size}x#{size}.png"
  end

  ##
  # @return [Enumerable<Hash>]
  #
  def self.file_sizes
    sql = "SELECT ins.id, ins.name, COUNT(b.id) AS count, SUM(b.length) AS sum,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY b.length) AS median,
        MAX(b.length) AS max
      FROM institutions ins
      LEFT JOIN items i ON i.institution_id = ins.id
      LEFT JOIN bitstreams b ON b.item_id = i.id
      GROUP BY ins.id
      ORDER BY ins.name;"
    connection.execute(sql)
  end

  ##
  # @param extension [String]
  # @return [String]
  #
  def self.footer_image_filename(extension)
    "footer.#{extension.gsub(".", "")}"
  end

  ##
  # @param institution_key [String]
  # @param extension [String] Filename extension.
  # @return [String]
  #
  def self.footer_image_key(institution_key, extension)
    [image_key_prefix(institution_key),
     footer_image_filename(extension)].join
  end

  ##
  # @param extension [String]
  # @return [String]
  #
  def self.header_image_filename(extension)
    "header.#{extension.gsub(".", "")}"
  end

  ##
  # @param institution_key [String]
  # @param extension [String] Filename extension.
  # @return [String]
  #
  def self.header_image_key(institution_key, extension)
    [image_key_prefix(institution_key),
     header_image_filename(extension)].join
  end

  ##
  # @param institution_key [String]
  # @return [String]
  #
  def self.image_key_prefix(institution_key)
    ["institutions", institution_key, "theme"].join("/") + "/"
  end

  ##
  # @return [Enumerable<Hash>]
  #
  def self.item_counts(include_buried: false)
    sql = "SELECT ins.id, ins.name, COUNT(i.id) AS count
      FROM institutions ins
      LEFT JOIN items i ON ins.id = i.institution_id "
    sql += "WHERE i.stage != #{Item::Stages::BURIED} " unless include_buried
    sql += "GROUP BY ins.id
      ORDER BY ins.name;"
    connection.execute(sql)
  end

  ##
  # @return [String] Presigned S3 URL.
  #
  def banner_image_url
    return nil if self.banner_image_filename.blank?
    key = [self.class.image_key_prefix(self.key),
           self.banner_image_filename].join
    PersistentStore.instance.public_url(key: key)
  end

  def breadcrumb_label
    name
  end

  def breadcrumb_parent
    Institution
  end

  ##
  # @return [MetadataProfile]
  #
  def default_metadata_profile
    self.metadata_profiles.where(institution_default: true).limit(1).first
  end

  ##
  # @return [SubmissionProfile]
  #
  def default_submission_profile
    self.submission_profiles.where(institution_default: true).limit(1).first
  end

  ##
  # @return [UserGroup] The user group that defines the instance's users.
  #
  def defining_user_group
    self.user_groups.where(defines_institution: true).limit(1).first
  end

  def delete_banner_image
    return if self.banner_image_filename.blank?
    key = self.class.image_key_prefix(self.key) + self.banner_image_filename
    PersistentStore.instance.delete_object(key: key)
    self.update!(banner_image_filename: nil)
  end

  def delete_favicons
    return unless self.has_favicon
    key_prefix = self.class.image_key_prefix(self.key) + "favicons/"
    PersistentStore.instance.delete_objects(key_prefix: key_prefix)
    self.update!(has_favicon: false)
  end

  def delete_footer_image
    return if self.footer_image_filename.blank?
    key = self.class.image_key_prefix(self.key) + self.footer_image_filename
    PersistentStore.instance.delete_object(key: key)
    self.update!(footer_image_filename: nil)
  end

  def delete_header_image
    return if self.header_image_filename.blank?
    key = self.class.image_key_prefix(self.key) + self.header_image_filename
    PersistentStore.instance.delete_object(key: key)
    self.update!(header_image_filename: nil)
  end

  ##
  # Compiles monthly download counts for a given time span by querying the
  # `events` table.
  #
  # Note that {MonthlyItemDownloadCount#for_institution} uses a different
  # technique--querying the monthly item download count reporting table--that
  # is much faster.
  #
  # @param start_time [Time]   Optional beginning of a time range, which will
  #                            get rounded down to the first of the month.
  # @param end_time [Time]     Optional end of a time range, which will get
  #                            rounded down to the first of the month.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys.
  #
  def download_count_by_month(start_time: nil, end_time: nil)
    start_time ||= Event.all.order(:happened_at).limit(1).pluck(:happened_at).first
    end_time   ||= Time.now.utc
    raise ArgumentError, "End time must be after start time" if start_time > end_time
    end_time    += 1.month
    start_series = "#{start_time.year}-#{start_time.month}-01"
    end_series   = "#{end_time.year}-#{end_time.month}-01"

    sql = "SELECT mon.month, coalesce(e.count, 0) AS dl_count
        FROM generate_series('#{start_series}'::timestamp,
                             '#{end_series}'::timestamp, interval '1 month') AS mon(month)
        LEFT JOIN (
            SELECT date_trunc('Month', e.happened_at) as month,
                   COUNT(DISTINCT e.id) AS count
            FROM events e
                LEFT JOIN bitstreams b ON e.bitstream_id = b.id
                LEFT JOIN items i ON b.item_id = i.id
                LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
                LEFT JOIN units u ON u.id = ucm.unit_id
            WHERE u.institution_id = $1
                AND e.event_type = $2
                AND e.happened_at >= $3
                AND e.happened_at <= $4
            GROUP BY month
        ) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [self.id, Event::Type::DOWNLOAD, start_time, end_time]
    result = self.class.connection.exec_query(sql, "SQL", values).to_a
    result[0..(result.length - 2)]
  end

  ##
  # @param size [Integer] One of the sizes defined in
  #                       {InstitutionsHelper#FAVICONS}.
  # @return [String] Presigned S3 URL.
  #
  def favicon_url(size:)
    return nil unless self.has_favicon
    key = [self.class.image_key_prefix(self.key),
           "favicons/",
           self.class.favicon_filename(size: size)].join
    PersistentStore.instance.public_url(key: key)
  end

  ##
  # @return [String] Presigned S3 URL.
  #
  def footer_image_url
    return nil if self.footer_image_filename.blank?
    key = [self.class.image_key_prefix(self.key),
           self.footer_image_filename].join
    PersistentStore.instance.public_url(key: key)
  end

  ##
  # @return [String] Presigned S3 URL.
  #
  def header_image_url
    return nil if self.header_image_filename.blank?
    key = [self.class.image_key_prefix(self.key),
           self.header_image_filename].join
    PersistentStore.instance.public_url(key: key)
  end

  ##
  # @return [Medusa::FileGroup, nil]
  #
  def medusa_file_group
    if !@file_group && self.medusa_file_group_id
      @file_group = Medusa::FileGroup.with_id(self.medusa_file_group_id)
    end
    @file_group
  end

  ##
  # Totally destroys an institution as well as all of its dependent entities.
  # This is strictly a convenience for testing and will raise an error in all
  # other environments.
  #
  def nuke!
    raise "You maniac, you can only nuke an institution in test!" unless Rails.env.test?
    self.imports.destroy_all
    self.users.destroy_all
    self.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bs|
            bs.destroy!
          end
          item.destroy!
        end
        collection.destroy!
      end
      unit.destroy!
    end
    self.destroy!
  end

  ##
  # @return [Integer]
  #
  def public_item_count
    Item.search.
      institution(self).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::APPROVED).
      limit(0).
      count
  end

  ##
  # Recreates derivative favicons from the master favicon present in the
  # bucket.
  #
  # @param task [Task] Optional.
  # @return [void]
  # @raises [RuntimeError] if the instance does not have a master favicon.
  #
  def regenerate_favicons(task: nil)
    raise "This institution does not have a master favicon" unless has_favicon
    begin
      Dir.mktmpdir do |tmpdir|
        key_prefix  = self.class.image_key_prefix(self.key) + "favicons/"
        master_key  = key_prefix + "favicon-original.png"
        master_path = File.join(tmpdir, "favicon-original.png")
        # Download the master favicon.
        PersistentStore.instance.get_object(key:             master_key,
                                            response_target: master_path)
        # Generate a bunch of resized derivatives and upload them.
        InstitutionsHelper::FAVICONS.each_with_index do |icon, index|
          deriv_path = "#{tmpdir}/favicon-#{icon[:size]}x#{icon[:size]}.png"
          `vipsthumbnail #{master_path} --size=#{icon[:size]}x#{icon[:size]} -o #{deriv_path}.v`
          `vips gravity #{deriv_path}.v #{deriv_path} centre #{icon[:size]} #{icon[:size]} --background "0, 0, 0, 0"`
          dest_key = "#{key_prefix}favicon-#{icon[:size]}x#{icon[:size]}.png"
          PersistentStore.instance.put_object(key:             dest_key,
                                              institution_key: self.key,
                                              path:            deriv_path,
                                              public:          true)
          task&.progress(index / InstitutionsHelper::FAVICONS.length.to_f)
        end
      end
    rescue => e
      task&.fail(detail: e.message, backtrace: e.backtrace)
      raise e
    end
    task&.succeed
  end

  ##
  # @return [Enumerable<RegisteredElement>] All system-required elements.
  #
  def required_elements
    [self.title_element, self.author_element, self.description_element]
  end

  ##
  # @return [String]
  #
  def scope_url
    scheme = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
    "#{scheme}://#{self.fqdn}"
  end

  ##
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys.
  #
  def submitted_item_count_by_month(start_time: nil, end_time: nil)
    start_time ||= Event.all.order(:happened_at).limit(1).pluck(:happened_at).first
    end_time   ||= Time.now.utc
    raise ArgumentError, "End time must be after start time" if start_time > end_time
    end_time    += 1.month
    start_series = "#{start_time.year}-#{start_time.month}-01"
    end_series   = "#{end_time.year}-#{end_time.month}-01"

    sql = "SELECT mon.month, coalesce(e.count, 0) AS count
        FROM generate_series('#{start_series}'::timestamp,
                             '#{end_series}'::timestamp, interval '1 month') AS mon(month)
            LEFT JOIN (
                SELECT date_trunc('Month', e.happened_at) as month,
                       COUNT(e.id) AS count
                FROM events e
                    LEFT JOIN items i ON e.item_id = i.id
                    LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                    LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
                    LEFT JOIN units u ON u.id = ucm.unit_id
                WHERE u.institution_id = $1
                    AND e.event_type = $2
                    AND e.happened_at >= $3
                    AND e.happened_at <= $4
                GROUP BY month) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [self.id, Event::Type::CREATE, start_time, end_time]
    result = self.class.connection.exec_query(sql, "SQL", values).to_a
    result[0..(result.length - 2)]
  end

  def to_param
    key
  end

  ##
  # @param io [IO]
  # @param extension [String]
  #
  def upload_banner_image(io:, extension:)
    filename = self.class.banner_image_filename(extension)
    upload_theme_image(io: io, filename: filename)
    self.update!(banner_image_filename: filename)
  end

  ##
  # Uploads a favicon image to the application bucket, generates several
  # resized derivatives of it, and uploads those too.
  #
  # The original or master favicon is saved in the bucket as
  # `favicon-original.png`. The resized derivatives are saved as
  # `favicon-WxH.png`.
  #
  # It is recommended to **not** invoke this from a controller action, and
  # instead invoke {UploadFaviconsJob} asynchronously.
  #
  # @param io [IO]
  # @param task [Task] Optional.
  # @see UploadFaviconsJob
  #
  def upload_favicon(io:, task: nil)
    # This method works differently than the other image upload methods,
    # because we are not simply putting contents of the io argument into the
    # bucket. Instead we are writing it to a temp file, making a bunch of
    # different sized derivatives of it, and uploading those.
    tempfile = Tempfile.new(["#{self.class}-#{self.key}-favicon", ".png"])
    begin
      tempfile.write(io.read)
      tempfile.close
      # Upload the "master favicon"
      key_prefix = self.class.image_key_prefix(self.key)
      dest_key   = key_prefix + "favicons/favicon-original.png"
      PersistentStore.instance.put_object(key:             dest_key,
                                          institution_key: self.key,
                                          path:            tempfile.path,
                                          public:          true)
      self.update!(has_favicon: true)
      regenerate_favicons(task: task)
      task&.succeed
    rescue => e
      task&.fail(detail: e.message, backtrace: e.backtrace)
      raise e
    ensure
      tempfile.unlink
    end
  end

  ##
  # @param io [IO]
  # @param extension [String]
  #
  def upload_footer_image(io:, extension:)
    filename = self.class.footer_image_filename(extension)
    upload_theme_image(io: io, filename: filename)
    self.update!(footer_image_filename: filename)
  end

  ##
  # @param io [IO]
  # @param extension [String]
  #
  def upload_header_image(io:, extension:)
    filename = self.class.header_image_filename(extension)
    upload_theme_image(io: io, filename: filename)
    self.update!(header_image_filename: filename)
  end

  ##
  # @return [String]
  #
  def url
    "https://#{fqdn}"
  end


  private

  def add_default_elements
    # These elements are used by default metadata mappings (see
    # add_default_metadata_mappings()) as Dublin Core does not have good
    # equivalents.
    self.registered_elements.build(name:             "ideals:date:submitted",
                                   label:            "Date Submitted",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD)
    self.registered_elements.build(name:             "ideals:date:approved",
                                   label:            "Date Approved",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD)
    self.registered_elements.build(name:             "ideals:date:published",
                                   label:            "Date Published",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD)
    self.registered_elements.build(name:             "ideals:handleURI",
                                   label:            "Handle URI",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD)

    self.registered_elements.build(name:             "dc:contributor",
                                   label:            "Contributor",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD)
    self.registered_elements.build(name:             "dc:contributor:advisor",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Dissertation Director of Research or Thesis Advisor")
    self.registered_elements.build(name:             "dc:contributor:committeeChair",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Dissertation Chair")
    self.registered_elements.build(name:             "dc:contributor:committeeMember",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Dissertation Committee Member")
    self.registered_elements.build(name:             "dc:coverage:spatial",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Geographic Coverage")
    self.registered_elements.build(name:             "dc:creator",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Creator",
                                   highwire_mapping: "citation_author")
    self.registered_elements.build(name:             "dc:date:issued",
                                   input_type:       RegisteredElement::InputType::DATE,
                                   label:            "Date of Publication",
                                   highwire_mapping: "citation_publication_date")
    self.registered_elements.build(name:             "dc:date:submitted",
                                   input_type:       RegisteredElement::InputType::DATE,
                                   label:            "Date Deposited")
    self.registered_elements.build(name:             "dc:description",
                                   input_type:       RegisteredElement::InputType::TEXT_AREA,
                                   label:            "Description")
    self.registered_elements.build(name:             "dc:description:abstract",
                                   input_type:       RegisteredElement::InputType::TEXT_AREA,
                                   label:            "Abstract")
    self.registered_elements.build(name:             "dc:description:sponsorship",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Sponsor/Grant No.")
    self.registered_elements.build(name:             "dc:identifier",
                                   label:            "Identifier",
                                   vocabulary:       Vocabulary.find_by_name("Degree Names"),
                                   highwire_mapping: "citation_id")
    self.registered_elements.build(name:             "dc:identifier:bibliographicCitation",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Complete Citation For This Item")
    self.registered_elements.build(name:             "dc:identifier:uri",
                                   label:            "Identifiers: URI or URL")
    self.registered_elements.build(name:             "dc:language",
                                   label:            "Language",
                                   vocabulary:       Vocabulary.find_by_name("Common ISO Languages"),
                                   highwire_mapping: "citation_language")
    self.registered_elements.build(name:             "dc:publisher",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Publisher",
                                   highwire_mapping: "citation_publisher")
    self.registered_elements.build(name:             "dc:relation:ispartof",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Series Name/Report No.")
    self.registered_elements.build(name:             "dc:rights",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Copyright Statement")
    self.registered_elements.build(name:             "dc:subject",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Keyword",
                                   highwire_mapping: "citation_keywords")
    self.registered_elements.build(name:             "dcterms:available",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Available")
    self.registered_elements.build(name:             "dcterms:identifier",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Handle URI")
    self.registered_elements.build(name:             "dc:title",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Title",
                                   highwire_mapping: "citation_title")
    self.registered_elements.build(name:             "dc:type",
                                   label:            "Type of Resource",
                                   vocabulary:       Vocabulary.find_by_name("Common Types"))
    self.registered_elements.build(name:             "dc:type:genre",
                                   label:            "Genre of Resource",
                                   vocabulary:       Vocabulary.find_by_name("Common Genres"))
    self.registered_elements.build(name:             "orcid:identifier",
                                   label:            "ORCID Identifier",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD)
    self.registered_elements.build(name:             "thesis:degree:department",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Dissertation/Thesis Degree Department")
    self.registered_elements.build(name:             "thesis:degree:discipline",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Dissertation/Thesis Degree Discipline")
    self.registered_elements.build(name:             "thesis:degree:grantor",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Degree Granting Institution")
    self.registered_elements.build(name:             "thesis:degree:level",
                                   label:            "Dissertation or Thesis",
                                   vocabulary:       Vocabulary.find_by_name("Dissertation Thesis"))
    self.registered_elements.build(name:             "thesis:degree:name",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Degree")
    self.registered_elements.build(name:             "thesis:degree:program",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Dissertation/Thesis Degree Program")
    self.save!
  end

  ##
  # N.B.: this must be invoked AFTER add_default_elements().
  #
  def add_default_index_pages
    page    = self.index_pages.build(name: "Creators")
    element = self.registered_elements.find_by_name("dc:creator")
    raise "No creator element (this is a bug)" unless element
    page.registered_elements << element
    page.save!
  end

  def add_default_element_mappings
    self.update!(title_element:          self.registered_elements.find_by_name("dc:title"),
                 author_element:         self.registered_elements.find_by_name("dc:creator"),
                 description_element:    self.registered_elements.find_by_name("dc:description"),
                 date_submitted_element: self.registered_elements.find_by_name("ideals:date:submitted"),
                 date_approved_element:  self.registered_elements.find_by_name("ideals:date:approved"),
                 date_published_element: self.registered_elements.find_by_name("ideals:date:published"),
                 handle_uri_element:     self.registered_elements.find_by_name("ideals:handleURI"))
  end

  def add_default_metadata_profile
    profile = self.metadata_profiles.build(name:                "Default Metadata Profile",
                                           institution_default: true)
    profile.save!
    profile.add_all_registered_elements
  end

  def add_default_submission_profile
    profile = self.submission_profiles.build(name:                "Default Submission Profile",
                                             institution_default: true)
    profile.save!
    profile.add_required_elements
  end

  def add_default_vocabularies
    vocab = self.vocabularies.build(name: "Common Genres")
    vocab.vocabulary_terms.build(stored_value:    "article",
                                 displayed_value: "Article")
    vocab.vocabulary_terms.build(stored_value:    "bibliography",
                                 displayed_value: "Bibliography")
    vocab.vocabulary_terms.build(stored_value:    "book",
                                 displayed_value: "Book")
    vocab.vocabulary_terms.build(stored_value:    "book_chapter",
                                 displayed_value: "Book Chapter")
    vocab.vocabulary_terms.build(stored_value:    "book_review",
                                 displayed_value: "Book Review")
    vocab.vocabulary_terms.build(stored_value:    "editorial",
                                 displayed_value: "Editorial")
    vocab.vocabulary_terms.build(stored_value:    "essay",
                                 displayed_value: "Essay")
    vocab.vocabulary_terms.build(stored_value:    "conference_paper",
                                 displayed_value: "Conference Paper / Presentation")
    vocab.vocabulary_terms.build(stored_value:    "conference_poster",
                                 displayed_value: "Conference Poster")
    vocab.vocabulary_terms.build(stored_value:    "conference_proceeding",
                                 displayed_value: "Conference Proceeding (whole)")
    vocab.vocabulary_terms.build(stored_value:    "data",
                                 displayed_value: "Data")
    vocab.vocabulary_terms.build(stored_value:    "dissertation/thesis",
                                 displayed_value: "Dissertation / Thesis")
    vocab.vocabulary_terms.build(stored_value:    "drawing",
                                 displayed_value: "Drawing")
    vocab.vocabulary_terms.build(stored_value:    "fiction",
                                 displayed_value: "Fiction")
    vocab.vocabulary_terms.build(stored_value:    "journal",
                                 displayed_value: "Journal (whole)")
    vocab.vocabulary_terms.build(stored_value:    "newsletter",
                                 displayed_value: "Newsletter")
    vocab.vocabulary_terms.build(stored_value:    "performance",
                                 displayed_value: "Performance")
    vocab.vocabulary_terms.build(stored_value:    "photograph",
                                 displayed_value: "Photograph")
    vocab.vocabulary_terms.build(stored_value:    "poetry",
                                 displayed_value: "Poetry")
    vocab.vocabulary_terms.build(stored_value:    "presentation/lecture/speech",
                                 displayed_value: "Presentation / Lecture / Speech")
    vocab.vocabulary_terms.build(stored_value:    "proposal",
                                 displayed_value: "Proposal")
    vocab.vocabulary_terms.build(stored_value:    "oral history",
                                 displayed_value: "Oral History")
    vocab.vocabulary_terms.build(stored_value:    "report",
                                 displayed_value: "Report (Grant or Annual)")
    vocab.vocabulary_terms.build(stored_value:    "score",
                                 displayed_value: "Score")
    vocab.vocabulary_terms.build(stored_value:    "technical report",
                                 displayed_value: "Technical Report")
    vocab.vocabulary_terms.build(stored_value:    "website",
                                 displayed_value: "Website")
    vocab.vocabulary_terms.build(stored_value:    "working paper",
                                 displayed_value: "Working / Discussion Paper")
    vocab.vocabulary_terms.build(stored_value:    "other",
                                 displayed_value: "Other")
    vocab.save!

    vocab = self.vocabularies.build(name: "Common ISO Languages")
    vocab.vocabulary_terms.build(stored_value:    "en",
                                 displayed_value: "English")
    vocab.vocabulary_terms.build(stored_value:    "zh",
                                 displayed_value: "Chinese")
    vocab.vocabulary_terms.build(stored_value:    "fr",
                                 displayed_value: "French")
    vocab.vocabulary_terms.build(stored_value:    "de",
                                 displayed_value: "German")
    vocab.vocabulary_terms.build(stored_value:    "it",
                                 displayed_value: "Italian")
    vocab.vocabulary_terms.build(stored_value:    "ja",
                                 displayed_value: "Japanese")
    vocab.vocabulary_terms.build(stored_value:    "es",
                                 displayed_value: "Spanish")
    vocab.vocabulary_terms.build(stored_value:    "tr",
                                 displayed_value: "Turkish")
    vocab.vocabulary_terms.build(stored_value:    "other",
                                 displayed_value: "Other")
    vocab.save!

    vocab = self.vocabularies.build(name: "Common Types")
    vocab.vocabulary_terms.build(stored_value:    "sound",
                                 displayed_value: "Audio")
    vocab.vocabulary_terms.build(stored_value:    "dataset",
                                 displayed_value: "Dataset / Spreadsheet")
    vocab.vocabulary_terms.build(stored_value:    "still image",
                                 displayed_value: "Image")
    vocab.vocabulary_terms.build(stored_value:    "text",
                                 displayed_value: "Text")
    vocab.vocabulary_terms.build(stored_value:    "moving image",
                                 displayed_value: "Video")
    vocab.vocabulary_terms.build(stored_value:    "other",
                                 displayed_value: "Other")
    vocab.save!

    vocab = self.vocabularies.build(name: "Degree Names")
    vocab.vocabulary_terms.build(stored_value:    "B.A. (bachelor's)",
                                 displayed_value: "B.A. (bachelor's)")
    vocab.vocabulary_terms.build(stored_value:    "B.S. (bachelor's)",
                                 displayed_value: "B.S. (bachelor's)")
    vocab.vocabulary_terms.build(stored_value:    "M.A. (master's)",
                                 displayed_value: "M.A. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.Arch. (master's)",
                                 displayed_value: "M.Arch. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.F.A. (master's)",
                                 displayed_value: "M.F.A. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.H.R.I.R. (master's)",
                                 displayed_value: "M.H.R.I.R. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.L.A. (master's)",
                                 displayed_value: "M.L.A. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.Mus. (master's)",
                                 displayed_value: "M.Mus. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.S. (master's)",
                                 displayed_value: "M.S. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.S.P.H. (master's)",
                                 displayed_value: "M.S.P.H. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "M.U.P. (master's)",
                                 displayed_value: "M.U.P. (master's)")
    vocab.vocabulary_terms.build(stored_value:    "A.Mus.D. (doctoral)",
                                 displayed_value: "A.Mus.D. (doctoral)")
    vocab.vocabulary_terms.build(stored_value:    "Au.D. (doctoral)",
                                 displayed_value: "Au.D. (doctoral)")
    vocab.vocabulary_terms.build(stored_value:    "Ed.D. (doctoral)",
                                 displayed_value: "Ed.D. (doctoral)")
    vocab.vocabulary_terms.build(stored_value:    "J.S.D. (doctoral)",
                                 displayed_value: "J.S.D. (doctoral)")
    vocab.vocabulary_terms.build(stored_value:    "Ph.D. (doctoral)",
                                 displayed_value: "Ph.D. (doctoral)")
    vocab.save!

    vocab = self.vocabularies.build(name: "Dissertation Thesis")
    vocab.vocabulary_terms.build(stored_value:    "Dissertation",
                                 displayed_value: "Dissertation (Doctoral level only)")
    vocab.vocabulary_terms.build(stored_value:    "Thesis",
                                 displayed_value: "Thesis (Bachelor's or Master's level)")
    vocab.save!
  end

  def add_default_user_groups
    self.user_groups.build(name:                "#{self.name} Users",
                           key:                 UserGroup::DEFINING_INSTITUTION_KEY,
                           defines_institution: true).save!
    self.user_groups.build(name:                "Institution Administrators",
                           key:                 "#{self.key}_admin",
                           defines_institution: false).save!
  end

  def disallow_key_changes
    if !new_record? && key_changed?
      errors.add(:key, "cannot be changed")
    end
  end

  ##
  # @param io [IO]
  # @param filename [String]
  #
  def upload_theme_image(io:, filename:)
    key = self.class.image_key_prefix(self.key) + filename
    PersistentStore.instance.put_object(key: key, io: io, public: true)
  end

  ##
  # Ensures that {shibboleth_org_dn} and {openathens_sp_entity_id} are not both
  # filled in.
  #
  def validate_authentication_method
    if self.shibboleth_org_dn.present? &&
      self.openathens_sp_entity_id.present?
      errors.add(:base, "Organization DN and OpenAthens SP entity ID "\
                        "cannot both be present")
    end
  end

  def validate_css_colors
    [:active_link_color,
     :footer_background_color,
     :header_background_color,
     :link_color,
     :link_hover_color,
     :primary_color,
     :primary_hover_color].each do |attr|
      value = send(attr)
      if value.present? && !ColorUtils.css_color?(value)
        errors.add(attr, "must be a valid CSS color")
      end
    end
  end

end
