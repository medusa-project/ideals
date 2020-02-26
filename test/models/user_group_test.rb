require 'test_helper'

class UserGroupTest < ActiveSupport::TestCase

  setup do
    @instance = user_groups(:one)
    assert @instance.valid?
  end

  test "name must be unique" do
    assert_raises ActiveRecord::RecordInvalid do
      UserGroup.create!(name: @instance.name)
    end
  end

end
