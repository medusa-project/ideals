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

  has_many :metadata_profiles
  has_many :registered_elements
  has_many :submission_profiles
  has_many :units

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

  def breadcrumb_label
    name
  end

  ##
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys.
  #
  def download_count_by_month(start_time: nil, end_time: nil)
    start_time = Event.all.order(:happened_at).limit(1).pluck(:happened_at).first unless start_time
    end_time   = Time.now unless end_time
    raise ArgumentError, "start_time > end_time" if start_time > end_time

    sql = "SELECT mon.month, coalesce(e.count, 0) AS dl_count
        FROM generate_series('#{start_time.strftime("%Y-%m-%d")}'::timestamp,
                             '#{end_time.strftime("%Y-%m-%d")}'::timestamp, interval '1 month') AS mon(month)
            LEFT JOIN (
                SELECT date_trunc('Month', e.happened_at) as month,
                       COUNT(e.id) AS count
                FROM events e
                    LEFT JOIN bitstreams b on e.bitstream_id = b.id
                    LEFT JOIN items i ON b.item_id = i.id
                    LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                    LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
                    LEFT JOIN units u ON u.id = ucm.unit_id
                WHERE u.institution_id = $1
                    AND e.event_type = $2
                    AND e.happened_at >= $3
                    AND e.happened_at <= $4
                GROUP BY month) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [self.id, Event::Type::DOWNLOAD, start_time, end_time]
    self.class.connection.exec_query(sql, "SQL", values)
  end

  ##
  # N.B.: Only items with ascribed titles are included in results.
  #
  # @param offset [Integer]    SQL OFFSET clause.
  # @param limit [Integer]     SQL LIMIT clause.
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes representing items and
  #                            their corresponding download counts.
  #
  def item_download_counts(offset: 0, limit: 0,
                           start_time: nil, end_time: nil)
    sql = StringIO.new
    sql << "SELECT *
        FROM (
            SELECT DISTINCT ON (i.id) i.id AS id, ae.string AS title, COUNT(e.id) AS dl_count
            FROM items i
                LEFT JOIN ascribed_elements ae ON ae.item_id = i.id
                LEFT JOIN registered_elements re ON re.id = ae.registered_element_id
                LEFT JOIN bitstreams b ON b.item_id = i.id
                LEFT JOIN events e ON e.bitstream_id = b.id
                LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
                LEFT JOIN units u ON u.id = ucm.unit_id
            WHERE re.name = $1
                AND u.institution_id = $2
                AND e.event_type = $3 "
    sql <<      "AND e.happened_at >= $4 " if start_time
    sql <<      "AND e.happened_at <= #{start_time ? "$5" : "$4"} " if end_time
    sql <<  "GROUP BY i.id, ae.string"
    sql << ") items_with_dl_count "
    sql << "ORDER BY items_with_dl_count.dl_count DESC "
    sql << "OFFSET #{offset} " if offset > 0
    sql << "LIMIT #{limit} " if limit > 0

    values = [
      ::Configuration.instance.elements[:title],
      self.id,
      Event::Type::DOWNLOAD
    ]
    values << start_time if start_time
    values << end_time if end_time
    self.class.connection.exec_query(sql.string, 'SQL', values)
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

  ##
  # @return [ActiveRecord::Relation<User>]
  #
  def users
    User.where(org_dn: self.org_dn)
  end


  private

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
