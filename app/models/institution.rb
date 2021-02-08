##
# # Attributes
#
# `created_at` Managed by ActiveRecord.
# `key`        Short string that uniquely identifies the institution.
#              Populated from the `org_dn` string upon save.
# `name`       Institution name, populated from the `org_dn` string upon save.
# `org_dn`     Value of an `eduPersonOrgDN` attribute from the Shibboleth SP.
# `updated_at` Managed by ActiveRecord.
#
class Institution < ApplicationRecord

  include Breadcrumb

  UIUC_ORG_DN = "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu"

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

  before_save :set_properties

  def label
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
