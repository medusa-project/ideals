require 'test_helper'

class AffiliationTest < ActiveSupport::TestCase

  test "from_shibboleth() returns a correct instance for an undergraduate
  student" do
    info = {
      extra: {
        raw_info: {
          iTrustAffiliation: "student;person;phone",
          programCode: "",
          levelCode: "1U"
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_shibboleth(info)
    assert_equal Affiliation::UNDERGRADUATE_STUDENT_KEY, affiliation.key
  end

  test "from_shibboleth() returns a correct instance for a graduate student" do
    info = {
      extra: {
        raw_info: {
          iTrustAffiliation: "student;person;phone",
          programCode: "",
          levelCode: "1V"
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_shibboleth(info)
    assert_equal Affiliation::GRADUATE_STUDENT_KEY, affiliation.key
  end

  test "from_shibboleth() returns a correct instance for a masters student" do
    info = {
      extra: {
        raw_info: {
          iTrustAffiliation: "student;person;phone",
          programCode: "something",
          levelCode: "1V"
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_shibboleth(info)
    assert_equal Affiliation::MASTERS_STUDENT_KEY, affiliation.key
  end

  test "from_shibboleth() returns a correct instance for a Ph.D student" do
    info = {
      extra: {
        raw_info: {
          iTrustAffiliation: "student;person;phone",
          programCode: "PHD",
          levelCode: ""
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_shibboleth(info)
    assert_equal Affiliation::PHD_STUDENT_KEY, affiliation.key
  end

  test "from_shibboleth() returns a correct instance for a staff member" do
    info = {
      extra: {
        raw_info: {
          iTrustAffiliation: "staff;person;phone",
          programCode: nil,
          levelCode: nil
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_shibboleth(info)
    assert_equal Affiliation::FACULTY_STAFF_KEY, affiliation.key
  end

  test "from_shibboleth() returns nil for an unrecognized affiliation" do
    info = {
      extra: {
        raw_info: {
          iTrustAffiliation: "bogus;cats;dogs",
          programCode: "",
          levelCode: "1U"
        }
      }
    }.deep_stringify_keys
    assert_nil Affiliation.from_shibboleth(info)
  end

  test "from_shibboleth() returns nil for an unrecognized level code" do
    info = {
      extra: {
        raw_info: {
          iTrustAffiliation: "student;cats;dogs",
          programCode: "",
          levelCode: "bogus"
        }
      }
    }.deep_stringify_keys
    assert_nil Affiliation.from_shibboleth(info)
  end

end
