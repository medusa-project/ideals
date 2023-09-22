# frozen_string_literal: true

##
# The root of the main entity tree, and a container for {Unit}s.
#
# Each institution has its own domain name at which its own website, scoped to
# its own content, is available. Its website has a distinct theme from other
# websites. It may also use its own authentication system.
#
# # Attributes
#
# * `active_link_color`         Theme active hyperlink color.
# * `author_element_id`         Foreign key to {RegisteredElement} designating
#                               an element to treat as the author element.
# * `banner_image_filename`     Filename of the banner image, which may exist
#                               in the application S3 bucket under
#                               {image_key_prefix}. If not present, a generic
#                               image is used.
# * `banner_image_height`       Height of the banner image.
# * `copyright_notice`          Generic institution-wide copyright notice,
#                               generally displayed on the website somewhere.
# * `created_at`                Managed by ActiveRecord.
# * `date_approved_element_id`  Foreign key to {RegisteredElement} designating
#                               an element to treat as the date-approved
#                               element.
# * `date_submitted_element_id` Foreign key to {RegisteredElement} designating
#                               an element to treat as the date-submitted
#                               element.
# * `deposit_agreement`         Deposit agreement for new item submissions.
# * `earliest_search_year`      Earliest year available in advanced search.
# * `feedback_email`            Email address for public feedback.
# * `footer_background_color`   Theme background color of the footer.
# * `footer_image_filename`     Filename of the footer image, which is expected
#                               to exist in the application S3 bucket under
#                               {image_key_prefix}.
# * `google_analytics_measurement_id` Google Analytics v4 measurement ID
#                               (a.k.a. key).
# * `handle_uri_element_id`     Foreign key to {RegisteredElement} designating
#                               an element to treat as the date-submitted
#                               element.
# * `has_favicon`               Whether the instance has a favicon, i.e.
#                               whether an institution admin has uploaded one.
#                               Unlike the other image-related attributes, the
#                               favicon's filenames are fixed.
# * `header_background_color`   Theme background color of the header.
# * `header_image_filename`     Filename of the header image, which is expected
#                               to exist in the application S3 bucket under
#                               {image_key_prefix}.
# * `key`                       Short string that uniquely and permanently
#                               identifies the institution.
# * `latitude_degrees`          Degrees component of the institution's
#                               latitude.
# * `latitude_minutes`          Minutes component of the institution's
#                               latitude.
# * `latitude_seconds`          Seconds component of the institution's
#                               latitude.
# * `link_color`                Theme hyperlink color.
# * `link_hover_color`          Theme hover-over-hyperlink color.
# * `local_auth_enabled`        Whether local-identity authentication is
#                               enabled.
# * `longitude_degrees`         Degrees component of the institution's
#                               longitude.
# * `longitude_minutes`         Minutes component of the institution's
#                               longitude.
# * `longitude_seconds`         Seconds component of the institution's
#                               longitude.
# * `main_website_url`          URL of the institution's main website.
# * `medusa_file_group_id`      ID of the Medusa file group in which the
#                               institution's content is stored.
# * `name`                      Institution name.
# * `primary_color`             Theme primary color.
# * `primary_hover_color`       Theme hover-over primary color.
# * `saml_auth_enabled`         Whether SAML authentication is enabled.
# * `saml_auto_cert_rotation`   If true, the SAML certificate will be
#                               automatically rotated out and replaced with a
#                               new one when it is close to expiration.
# * `saml_config_metadata_url`  SAML configuration metadata XML URL. This may
#                               be used for institutions that are not a member
#                               of a recognized federation (for which this URL
#                               is already known and hard-coded into the app)
#                               to assist in populating the other required SAML
#                               properties.
# * `saml_email_attribute`      Name of the SAML attribute containing the email
#                               address. Used only when `saml_email_location`
#                               is set to
#                               {#Institution::SAMLEmailLocation::ATTRIBUTE}.
# * `saml_email_location`       One of the {Institution::SAMLEmailLocation}
#                               constant values. Required by institutions that
#                               use SAML for authentication.
# * `saml_first_name_attribute` Name of the SAML attribute containing a user's
#                               first name. Needed only by institutions that
#                               use SAML for authentication.
# * `saml_last_name_attribute`  Name of the SAML attribute containing a user's
#                               last name. Needed only by institutions that use
#                               SAML for authentication.
# * `saml_idp_cert`             Required only by institutions that use SAML for
#                               authentication.
# * `saml_idp_cert2`            Facilitates seamless rollover of IdP
#                               certificates.
# * `saml_idp_entity_id`        Required only by institutions that use SAML for
#                               authentication.
# * `saml_idp_sso_service_url`  Required only by institutions that use SAML for
#                               authentication.
# * `saml_sp_next_public_cert`  SAML X.509 public certificate with a later
#                               expiration than {saml_sp_public_cert} to
#                               facilitate seamless rollover when the latter
#                               expires.
# * `saml_sp_private_key`       SAML private key as a PEM-format string.
# * `saml_sp_public_cert`       SAML X.509 public certificate (generated from
#                               {saml_sp_private_key}) as a PEM-format string.
# * `service_name`              Name of the service that the institution is
#                               running. For example, at UIUC, this would be
#                               "IDEALS."
# * `shibboleth_auth_enabled`   Whether Shibboleth authentication is enabled.
# * `shibboleth_email_attribute` Shibboleth email attribute.
# * `shibboleth_extra_attributes` Array of extra attributes to request from the
#                               Shibboleth IdP. This can also be set to a
#                               comma-separated string which will be
#                               transformed into an array upon save.
# * `shibboleth_name_attribute` Shibboleth name attribute.
# * `shibboleth_org_dn`         Value of an `eduPersonOrgDN` attribute from the
#                               Shibboleth IdP. This should be filled in by all
#                               institutions that use Shibboleth for
#                               authentication (currently only UIUC).
# * `sso_federation`            Set to one of the {Institution::SSOFederation}
#                               constant values.
# * `submissions_reviewed`      When a new {Collection} is created, its
#                               {Collection#submissions_reviewed} property is
#                               set to this value.
# * `title_element_id`          Foreign key to {RegisteredElement} designating
#                               an element to treat as the title element.
# * `updated_at`                Managed by ActiveRecord.
# * `welcome_html`              HTML text that appears on the main page.
#
class Institution < ApplicationRecord

  include Breadcrumb

  class SAMLEmailLocation
    NAMEID    = 0
    ATTRIBUTE = 1

    def self.all
      self.constants.map{ |c| self.const_get(c) }.sort
    end

    def self.label_for(value)
      case value
      when NAMEID
        "NameID"
      when ATTRIBUTE
        "Attribute"
      else
        "Unknown"
      end
    end
  end

  class SSOFederation
    NONE       = 2
    ITRUST     = 0
    OPENATHENS = 1

    def self.label_for(value)
      case value
      when NONE
        "None"
      when ITRUST
        "iTrust"
      when OPENATHENS
        "OpenAthens"
      else
        "Unknown"
      end
    end
  end

  MIN_KEY_LENGTH          = 2
  MAX_KEY_LENGTH          = 30
  ITRUST_METADATA_URL     = "https://md.itrust.illinois.edu/itrust-metadata/itrust-metadata.xml"
  OPENATHENS_METADATA_URL = "http://fed.openathens.net/oafed/metadata"
  SAML_METADATA_NS        = "urn:oasis:names:tc:SAML:2.0:metadata"
  XML_DS_NS               = "http://www.w3.org/2000/09/xmldsig#"

  belongs_to :author_element, class_name: "RegisteredElement",
             foreign_key: :author_element_id, optional: true
  belongs_to :date_approved_element, class_name: "RegisteredElement",
             foreign_key: :date_approved_element_id, optional: true
  belongs_to :date_submitted_element, class_name: "RegisteredElement",
             foreign_key: :date_submitted_element_id, optional: true
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
  has_many :deposit_agreement_questions
  has_many :downloads
  has_many :element_namespaces
  has_many :events
  has_many :imports
  has_many :index_pages
  has_many :invitees
  has_many :logins
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

  serialize :shibboleth_extra_attributes, JSON

  validates :feedback_email, allow_blank: true, length: {maximum: 255},
            format: {with: StringUtils::EMAIL_REGEX}

  # uniqueness enforced by database constraints
  validates :fqdn, presence: true

  # uniqueness enforced by database constraints
  validates :medusa_file_group_id, allow_nil: true,
            numericality: { only_integer: true }

  validates :active_link_color, presence: true
  validates_presence_of :deposit_form_disagreement_help
  validates :footer_background_color, presence: true
  validates :header_background_color, presence: true
  validates :key, length: { minimum: MIN_KEY_LENGTH, maximum: MAX_KEY_LENGTH }
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
  validates :saml_email_location, inclusion: { in: SAMLEmailLocation.all },
            allow_blank: true
  validates :service_name, presence: true

  validate :disallow_key_changes, :validate_css_colors

  # N.B.: order is important!
  after_create :add_default_deposit_agreement_questions,
               :add_default_vocabularies, :add_default_elements,
               :add_default_element_mappings, :add_default_element_namespaces,
               :add_default_metadata_profile, :add_default_submission_profile,
               :add_default_index_pages, :add_default_user_groups

  before_save :arrayize_shibboleth_extra_attributes_csv

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
  # @param federation [Integer] One of the {SSOFederation} constant values.
  #                             Required if `url` is not supplied.
  # @param url [String]         Required if `federation` is not supplied.
  # @return [File]              SSO federation metadata XML file.
  #
  def self.fetch_saml_config_metadata(federation: nil, url: nil)
    if federation.present? && url.present?
      raise ArgumentError, "federation and url cannot both be provided"
    end
    if federation
      case federation
      when SSOFederation::ITRUST
        url = ITRUST_METADATA_URL
      when SSOFederation::OPENATHENS
        url = OPENATHENS_METADATA_URL
      else
        raise ArgumentError, "Unrecognized federation"
      end
    end
    path = "/tmp/metadata-#{SecureRandom.hex}.xml"
    `curl -sSo #{path} #{url}`
    return File.new(path)
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
  # @return [Boolean] Whether at least one authentication method is enabled.
  #
  def auth_enabled?
    local_auth_enabled || saml_auth_enabled || shibboleth_auth_enabled
  end

  ##
  # @return [String]
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
  # @return [String]
  #
  def favicon_url(size:)
    return nil unless self.has_favicon
    key = [self.class.image_key_prefix(self.key),
           "favicons/",
           self.class.favicon_filename(size: size)].join
    PersistentStore.instance.public_url(key: key)
  end

  ##
  # @return [Enumerable<Hash>] Hash with `:count`, `:sum`, `:mean`, `:median`,
  #                            and `:max` keys.
  #
  def file_stats
    sql = "SELECT COUNT(b.id) AS count, SUM(b.length) AS sum,
        AVG(b.length) AS mean,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY b.length) AS median,
        MAX(b.length) AS max
      FROM institutions ins
      LEFT JOIN items i ON i.institution_id = ins.id
      LEFT JOIN bitstreams b ON b.item_id = i.id
      WHERE ins.id = $1;"
    values = [self.id]
    self.class.connection.exec_query(sql, "SQL", values)[0].symbolize_keys
  end

  ##
  # @return [String]
  #
  def footer_image_url
    return nil if self.footer_image_filename.blank?
    key = [self.class.image_key_prefix(self.key),
           self.footer_image_filename].join
    PersistentStore.instance.public_url(key: key)
  end

  ##
  # @return [String]
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
          size       = "#{icon[:size]}x#{icon[:size]}"
          `convert #{master_path} -background none -resize #{size} -gravity center -extent #{size} #{deriv_path}`
          dest_key   = "#{key_prefix}favicon-#{icon[:size]}x#{icon[:size]}.png"
          PersistentStore.instance.put_object(key:    dest_key,
                                              path:   deriv_path,
                                              public: true)
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
  # @return [Enumerable<String>] Unique prefixes of all registered elements.
  #
  def registered_element_prefixes
    self.registered_elements.
      pluck(:name).
      map{ |n| n.split(":") }.
      reject{ |n| n.length < 2 }. # exclude unprefixed elements
      map(&:first).
      uniq.
      sort
  end

  ##
  # @return [Enumerable<RegisteredElement>] All system-required elements.
  #
  def required_elements
    [self.title_element, self.author_element]
  end

  ##
  # @return [String]
  #
  def saml_sp_entity_id
    [scope_url, "entity"].join("/")
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
  # @param metadata_xml_file [File]
  #
  def update_from_saml_config_metadata(metadata_xml_file)
    File.open(metadata_xml_file) do |file|
      doc        = Nokogiri::XML(file)
      sp_entity  = doc.xpath("//md:EntityDescriptor[@entityID = '#{self.saml_sp_entity_id}']",
                             md: SAML_METADATA_NS).first
      idp_entity = doc.xpath("//md:EntityDescriptor[@entityID = '#{self.saml_idp_entity_id}']",
                             md: SAML_METADATA_NS).first
      if sp_entity
        # IdP SSO service URL
        # Does the SP's EntityDescriptor contain an IDPSSODescriptor with an
        # SSO service URL?
        self.saml_idp_sso_service_url = sp_entity.xpath("./md:IDPSSODescriptor/md:SingleSignOnService[@Binding = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect']/@Location",
                                                        md: SAML_METADATA_NS).first&.text
        if self.saml_idp_sso_service_url.blank?
          # Does its IdP's EntityDescriptor contain one?
          self.saml_idp_sso_service_url = idp_entity.xpath("./md:IDPSSODescriptor/md:SingleSignOnService[@Binding = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect']/@Location",
                                                           md: SAML_METADATA_NS).first&.text
          if self.saml_idp_sso_service_url.blank?
            raise "No matching SP or IdP entityID found in federation metadata"
          end
        end
        # IdP cert
        self.saml_idp_cert = "-----BEGIN CERTIFICATE-----\n" +
          idp_entity.xpath("//ds:X509Certificate", ds: XML_DS_NS).first.text.strip +
          "\n-----END CERTIFICATE-----"
        self.save!
      else
        raise "No matching SP entityID found in federation metadata"
      end
    end
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
      PersistentStore.instance.put_object(key:    dest_key,
                                          path:   tempfile.path,
                                          public: true)
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

  def add_default_deposit_agreement_questions
    q = self.deposit_agreement_questions.build(text: "Do you agree to the "\
                                                     "deposit agreement in "\
                                                     "its entirety?",
                                               position: 0)
    q.responses.build(text: "Yes", position: 0, success: true)
    q.responses.build(text: "No", position: 1, success: false)
    q.save!
  end

  def add_default_elements
    RegisteredElement.where(template: true).each do |tpl_e|
      dup             = tpl_e.dup
      dup.institution = self
      dup.template    = false
      dup.scope_note  = "Default element added upon creation of the institution."
      dup.created_at  = Time.now
      dup.updated_at  = Time.now
      dup.save!
    end
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
                 date_submitted_element: self.registered_elements.find_by_name("dcterms:dateSubmitted"),
                 date_approved_element:  self.registered_elements.find_by_name("dcterms:dateAccepted"),
                 handle_uri_element:     self.registered_elements.find_by_name("dcterms:identifier"))
  end

  def add_default_element_namespaces
    self.element_namespaces.build(prefix: "dc",
                                  uri:    "http://purl.org/dc/elements/1.1/")
    self.element_namespaces.build(prefix: "dcterms",
                                  uri:    "http://purl.org/dc/terms/")
    self.element_namespaces.build(prefix: "orcid",
                                  uri:    "http://dbpedia.org/ontology/orcidId")
    self.save!
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
    # Normal users
    users  = self.user_groups.build(name:                "#{self.name} Users",
                                    key:                 UserGroup::DEFINING_INSTITUTION_KEY,
                                    defines_institution: true)
    users.save!
    # Institution admins
    admins = self.user_groups.build(name:                "Institution Administrators",
                                    key:                 "#{self.key}_admin",
                                    defines_institution: false)
    admins.save!
    self.administrator_groups.build(user_group: admins).save!
  end

  ##
  # {shibboleth_extra_attributes} is a serialized array. This method allows us
  # to set it to a comma-separated string (from e.g. a textarea) and have it
  # auto-transformed into an array.
  #
  def arrayize_shibboleth_extra_attributes_csv
    if self.shibboleth_extra_attributes.kind_of?(String) &&
      self.shibboleth_extra_attributes&.include?(",") &&
      !self.shibboleth_extra_attributes.start_with?("[") &&
      !self.shibboleth_extra_attributes.end_with?("]")
      self.shibboleth_extra_attributes =
        self.shibboleth_extra_attributes.split(",").map(&:strip)
    end
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
