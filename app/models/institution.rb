##
# # Attributes
#
# `created_at` Managed by ActiveRecord.
# `default`    Boolean flag indicating whether a particular institution is the
#              system default, i.e. the one that should be used when there is
#              no other information available (like an `X-Forwarded-Host`
#              header) to determine which one to use. Only one institution has
#              this set to true.
# `key`        Short string that uniquely identifies the institution.
#              Populated from the `org_dn` string upon save.
# `name`       Institution name, populated from the `org_dn` string upon save.
# `org_dn`     Value of an `eduPersonOrgDN` attribute from the Shibboleth SP.
# `updated_at` Managed by ActiveRecord.
#
class Institution < ApplicationRecord

  include Breadcrumb

  has_many :administrators, class_name: "InstitutionAdministrator"
  has_many :administering_users, through: :administrators,
           class_name: "User", source: :user
  has_many :administrator_groups, class_name: "InstitutionAdministratorGroup"
  has_many :administering_groups, through: :administrator_groups,
           class_name: "UserGroup", source: :user_group
  has_many :imports
  has_many :invitees
  has_many :metadata_profiles
  has_many :registered_elements
  has_many :submission_profiles
  has_many :tasks
  has_many :units
  has_many :user_groups
  has_many :users

  # uniqueness enforced by database constraints
  validates :fqdn, presence: true

  validates_format_of :fqdn,
                      # Rough but good enough
                      # Credit: https://stackoverflow.com/a/20204811
                      with: /(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)/

  # uniqueness enforced by database constraints
  validates :key, presence: true

  # uniqueness enforced by database constraints
  validates :name, presence: true

  # uniqueness enforced by database constraints
  validates :org_dn, presence: true

  validate :disallow_key_changes

  before_save :set_properties, :ensure_default_uniqueness
  after_create :add_default_elements, :add_default_metadata_profile,
               :add_default_submission_profile

  ##
  # @return [Institution] The default institution.
  #
  def self.default
    Institution.find_by_default(true)
  end

  def breadcrumb_label
    name
  end

  def breadcrumb_parent
    Institution
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
    start_time = Event.all.order(:happened_at).limit(1).pluck(:happened_at).first unless start_time
    end_time   = Time.now.utc unless end_time
    raise ArgumentError, "start_time > end_time" if start_time > end_time
    start_series = "#{start_time.year}-#{start_time.month}-01"
    end_series   = Date.civil(end_time.year, end_time.month, -1) # last day of month

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
    self.class.connection.exec_query(sql, "SQL", values)
  end

  ##
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys.
  #
  def submitted_item_count_by_month(start_time: nil, end_time: nil)
    start_time = Event.all.order(:happened_at).limit(1).pluck(:happened_at).first unless start_time
    end_time   = Time.now unless end_time

    sql = "SELECT mon.month, coalesce(e.count, 0) AS count
        FROM generate_series('#{start_time.strftime("%Y-%m-%d")}'::timestamp,
                             '#{end_time.strftime("%Y-%m-%d")}'::timestamp, interval '1 month') AS mon(month)
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
    self.class.connection.exec_query(sql, "SQL", values)
  end

  def to_param
    key
  end

  ##
  # @return [String]
  #
  def url
    "https://#{fqdn}"
  end


  private

  def add_default_elements
    # N.B.: when this app was first launched at UIUC, the elements with which
    # it was launched were imported from DSpace. This list is, for now, a
    # duplicate of those.
    # See: https://uofi.app.box.com/notes/593479281190
    # Also see: IdealsSeeder.update_registered_elements()
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
    self.registered_elements.build(name:             "dc:description:abstract",
                                   input_type:       RegisteredElement::InputType::TEXT_AREA,
                                   label:            "Abstract")
    self.registered_elements.build(name:             "dc:description:sponsorship",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Sponsor/Grant No.")
    self.registered_elements.build(name:             "dc:identifier",
                                   label:            "Identifier",
                                   vocabulary_key:   Vocabulary::Key::DEGREE_NAMES,
                                   highwire_mapping: "citation_id")
    self.registered_elements.build(name:             "dc:identifier:bibliographicCitation",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Complete Citation For This Item")
    self.registered_elements.build(name:             "dc:identifier:uri",
                                   label:            "Identifiers: URI or URL")
    self.registered_elements.build(name:             "dc:language",
                                   label:            "Language",
                                   vocabulary_key:   Vocabulary::Key::COMMON_ISO_LANGUAGES,
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
    self.registered_elements.build(name:             "dc:title",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Title",
                                   highwire_mapping: "citation_title")
    self.registered_elements.build(name:             "dc:type",
                                   label:            "Type of Resource",
                                   vocabulary_key:   Vocabulary::Key::COMMON_TYPES)
    self.registered_elements.build(name:             "dc:type:genre",
                                   label:            "Genre of Resource",
                                   vocabulary_key:   Vocabulary::Key::COMMON_GENRES)
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
                                   vocabulary_key:   Vocabulary::Key::DISSERTATION_THESIS)
    self.registered_elements.build(name:             "thesis:degree:name",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Degree")
    self.registered_elements.build(name:             "thesis:degree:program",
                                   input_type:       RegisteredElement::InputType::TEXT_FIELD,
                                   label:            "Dissertation/Thesis Degree Program")
    self.save!
  end

  def add_default_metadata_profile
    profile = self.metadata_profiles.build(name:    "Default Metadata Profile",
                                           default: true)
    profile.save!
    profile.add_default_elements
  end

  def add_default_submission_profile
    profile = self.submission_profiles.build(name:    "Default Submission Profile",
                                             default: true)
    profile.save!
    profile.add_default_elements
  end

  def disallow_key_changes
    if !new_record? && key_changed?
      errors.add(:key, "cannot be changed")
    end
  end

  ##
  # Ensures that only one institution is set as default.
  #
  def ensure_default_uniqueness
    if self.default && self.default_changed?
      Institution.where(default: true).
        where("id != ?", self.id).
        update_all(default: false)
    end
  end

  ##
  # Sets the key and name properties using the `org_dn` string.
  #
  def set_properties
    if org_dn.present?
      org_dn.split(",").each do |part|
        kv = part.split("=")
        if kv.length == 2 # should always be true
          if kv[0] == "o"
            self.name = kv[1]
          elsif kv[0] == "dc" && kv[1] != "edu"
            self.key = kv[1]
          end
        end
      end
    end
  end

end
