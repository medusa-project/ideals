# frozen_string_literal: true

##
# University affiliation associated with {UserGroup} and UIUC users.
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

  ITRUST_AFFILIATION_ATTRIBUTE  = "urn:oid:1.3.6.1.4.1.11483.101.1"
  ITRUST_LEVEL_CODE_ATTRIBUTE   = "urn:oid:1.3.6.1.4.1.11483.1.42"
  ITRUST_PROGRAM_CODE_ATTRIBUTE = "urn:oid:1.3.6.1.4.1.11483.1.40"

  ##
  # @param info [Hash] OmniAuth auth hash.
  #
  def self.from_omniauth(info)
    key  = nil
    info = info.dig("extra", "raw_info")
    if info # this will be nil when using the OmniAuth developer strategy
      info = info.deep_stringify_keys
      # Explanation of this logic:
      # https://uofi.app.box.com/notes/801448983786?s=5k6iiozlhp5mui5b4vrbskn3pu968j8r
      if info[ITRUST_AFFILIATION_ATTRIBUTE].include?("staff") ||
          info[ITRUST_AFFILIATION_ATTRIBUTE].include?("allied")
        key = FACULTY_STAFF_KEY
      elsif info[ITRUST_AFFILIATION_ATTRIBUTE].include?("student")
        if %w(1G 1V 1M 1L).include?(info[ITRUST_LEVEL_CODE_ATTRIBUTE])
          key = GRADUATE_STUDENT_KEY
        elsif info[ITRUST_LEVEL_CODE_ATTRIBUTE] == "1U"
          key = UNDERGRADUATE_STUDENT_KEY
        end
        if %w(PHD CAS).include?(info[ITRUST_PROGRAM_CODE_ATTRIBUTE])
          key = PHD_STUDENT_KEY
        elsif info[ITRUST_PROGRAM_CODE_ATTRIBUTE].present?
          key = MASTERS_STUDENT_KEY
        end
      end
    end
    key ? Affiliation.find_by_key(key) : nil
  end

end
