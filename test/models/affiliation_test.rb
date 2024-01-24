require 'test_helper'

class AffiliationTest < ActiveSupport::TestCase

  test "from_omniauth() returns a correct instance for a UIUC undergraduate
  student" do
    info = {
      extra: {
        raw_info: {
          Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
          Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => "",
          Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => "1U"
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_omniauth(info)
    assert_equal Affiliation::UNDERGRADUATE_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC graduate
  student" do
    info = {
      extra: {
        raw_info: {
          Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
          Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => "",
          Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => "1V"
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_omniauth(info)
    assert_equal Affiliation::GRADUATE_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC masters
  student" do
    info = {
      extra: {
        raw_info: {
          Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
          Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => "something",
          Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => "1V"
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_omniauth(info)
    assert_equal Affiliation::MASTERS_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC Ph.D student" do
    info = {
      extra: {
        raw_info: {
          Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
          Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => "PHD",
          Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => ""
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_omniauth(info)
    assert_equal Affiliation::PHD_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC staff member" do
    info = {
      extra: {
        raw_info: {
          Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[staff person phone],
          Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => nil,
          Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => nil
        }
      }
    }.deep_stringify_keys
    affiliation = Affiliation.from_omniauth(info)
    assert_equal Affiliation::FACULTY_STAFF_KEY, affiliation.key
  end

  test "from_omniauth() returns nil for an unrecognized affiliation" do
    info = {
      extra: {
        raw_info: {
          Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[bogus cats dogs],
          Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => "",
          Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => "1U"
        }
      }
    }.deep_stringify_keys
    assert_nil Affiliation.from_omniauth(info)
  end

  test "from_omniauth() returns nil for an unrecognized level code" do
    info = {
      extra: {
        raw_info: {
          Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student cats dogs],
          Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => "",
          Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => "bogus"
        }
      }
    }.deep_stringify_keys
    assert_nil Affiliation.from_omniauth(info)
  end

  test "from_omniauth() returns nil for a missing raw_info hash" do
    info = {
      extra: {}
    }.deep_stringify_keys
    assert_nil Affiliation.from_omniauth(info)
  end

end
