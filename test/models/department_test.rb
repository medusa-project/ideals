require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase

  setup do
    @instance = departments(:basket_weaving)
  end

  # from_omniauth()

  test "from_omniauth() returns nil if the argument is empty" do
    attrs = OneLogin::RubySaml::Attributes.new
    assert_nil Department.from_omniauth(attrs)
  end

  test "from_omniauth() returns nil if the given attributes do not contain a
  department name" do
    attrs = OneLogin::RubySaml::Attributes.new({
                                                 Department::SAML_DEPARTMENT_CODE_ATTRIBUTE => [""]
                                               })
    assert_nil Department.from_omniauth(attrs)
  end

  test "from_omniauth() returns a correct instance" do
    attrs = OneLogin::RubySaml::Attributes.new({
      Department::SAML_DEPARTMENT_CODE_ATTRIBUTE => ["bugs"]
    })
    dept = Department.from_omniauth(attrs)
    assert_equal "bugs", dept.name
  end

  # name

  test "name is normalized" do
    @instance.name = " test  test "
    assert_equal "test test", @instance.name
  end

end
