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

  SAML_AFFILIATION_ATTRIBUTE  = "urn:oid:1.3.6.1.4.1.11483.101.1"
  SAML_LEVEL_CODE_ATTRIBUTE   = "urn:oid:1.3.6.1.4.1.11483.1.42"
  SAML_PROGRAM_CODE_ATTRIBUTE = "urn:oid:1.3.6.1.4.1.11483.1.40"

  ##
  # @param attrs [OneLogin::RubySaml::Attributes]
  # @return [Affiliation]
  #
  def self.from_omniauth(attrs)
    key = nil
    # Explanation of this logic:
    # https://uofi.app.box.com/notes/801448983786?s=5k6iiozlhp5mui5b4vrbskn3pu968j8r
    affiliation_attr  = attrs[SAML_AFFILIATION_ATTRIBUTE] || ""
    level_code_attr   = attrs[SAML_LEVEL_CODE_ATTRIBUTE] || ""
    program_code_attr = attrs[SAML_PROGRAM_CODE_ATTRIBUTE] || ""
    if affiliation_attr.include?("staff") || affiliation_attr.include?("allied")
      key = FACULTY_STAFF_KEY
    elsif affiliation_attr.include?("student")
      if %w(1G 1V 1M 1L).include?(level_code_attr)
        key = GRADUATE_STUDENT_KEY
      elsif level_code_attr == "1U"
        key = UNDERGRADUATE_STUDENT_KEY
      end
      if program_code_attr.include?("PHD") || program_code_attr.include?("CAS")
        key = PHD_STUDENT_KEY
      elsif program_code_attr.present?
        key = MASTERS_STUDENT_KEY
      end
    end
    key ? Affiliation.find_by_key(key) : nil
  end

end
