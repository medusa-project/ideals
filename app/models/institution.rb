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
