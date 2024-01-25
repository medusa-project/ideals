require 'test_helper'

class AffiliationTest < ActiveSupport::TestCase

  test "from_omniauth() returns nil if the argument is empty" do
    attrs = OneLogin::RubySaml::Attributes.new
    assert_nil Affiliation.from_omniauth(attrs)
  end

  test "from_omniauth() returns a correct instance for a UIUC undergraduate
  student" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
      Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => [""],
      Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => ["1U"]
    })
    affiliation = Affiliation.from_omniauth(attrs)
    assert_equal Affiliation::UNDERGRADUATE_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC graduate
  student" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
      Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => [""],
      Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => ["1V"]
    })
    affiliation = Affiliation.from_omniauth(attrs)
    assert_equal Affiliation::GRADUATE_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC masters
  student" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
      Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => ["something"],
      Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => ["1V"]
    })
    affiliation = Affiliation.from_omniauth(attrs)
    assert_equal Affiliation::MASTERS_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC Ph.D student" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student person phone],
      Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => ["PHD"],
      Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => [""]
    })
    affiliation = Affiliation.from_omniauth(attrs)
    assert_equal Affiliation::PHD_STUDENT_KEY, affiliation.key
  end

  test "from_omniauth() returns a correct instance for a UIUC staff member" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[staff person phone],
      Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => [nil],
      Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => [nil]
    })
    affiliation = Affiliation.from_omniauth(attrs)
    assert_equal Affiliation::FACULTY_STAFF_KEY, affiliation.key
  end

  test "from_omniauth() returns nil for an unrecognized affiliation" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[bogus cats dogs],
      Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => [""],
      Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => ["1U"]
    })
    assert_nil Affiliation.from_omniauth(attrs)
  end

  test "from_omniauth() returns nil for an unrecognized level code" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Affiliation::ITRUST_AFFILIATION_ATTRIBUTE  => %w[student cats dogs],
      Affiliation::ITRUST_PROGRAM_CODE_ATTRIBUTE => [""],
      Affiliation::ITRUST_LEVEL_CODE_ATTRIBUTE   => ["bogus"]
    })
    assert_nil Affiliation.from_omniauth(attrs)
  end

end
