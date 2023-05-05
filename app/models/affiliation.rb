##
# University affiliation associated with {UserGroup} and
# {#User::AuthType::SHIBBOLETH Shibboleth} users.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `key`        Unique and stable key identifying the instance.
# * `name`       Name of the affiliation.
# * `updated_at` Managed by ActiveRecord.
#
class Affiliation < ApplicationRecord

  has_one :user
  has_and_belongs_to_many :user_groups

  FACULTY_STAFF_KEY         = "staff"
  GRADUATE_STUDENT_KEY      = "graduate"
  MASTERS_STUDENT_KEY       = "masters"
  PHD_STUDENT_KEY           = "phd"
  UNDERGRADUATE_STUDENT_KEY = "undergrad"

  ##
  # @param info [Hash] Shibboleth auth hash.
  #
  def self.from_shibboleth(info)
    key  = nil
    info = info.dig("extra", "raw_info")
    if info # this will be nil when using the OmniAuth developer strategy
      info = info.symbolize_keys
      # Explanation of this logic:
      # https://uofi.app.box.com/notes/801448983786?s=5k6iiozlhp5mui5b4vrbskn3pu968j8r
      if info[:iTrustAffiliation].match?(/staff|allied/)
        key = FACULTY_STAFF_KEY
      elsif info[:iTrustAffiliation].include?("student")
        if %w(1G 1V 1M 1L).include?(info[:levelCode])
          key = GRADUATE_STUDENT_KEY
        elsif info[:levelCode] == "1U"
          key = UNDERGRADUATE_STUDENT_KEY
        end
        if %w(PHD CAS).include?(info[:programCode])
          key = PHD_STUDENT_KEY
        elsif info[:programCode].present?
          key = MASTERS_STUDENT_KEY
        end
      end
    end
    key ? Affiliation.find_by_key(key) : nil
  end

end
