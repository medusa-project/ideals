require 'test_helper'

class UnitCollectionMembershipTest < ActiveSupport::TestCase

  setup do
    @instance = unit_collection_memberships(:uiuc_unit1_collection1)
  end

  # unit_default

  test "setting an instance as the unit default sets all other instances to
  not-unit-default" do
    unit = units(:uiuc_unit1)

    # assert the initial unit-default membership
    memberships = unit.unit_collection_memberships.where(unit_default: true)
    assert_equal 1, memberships.count
    assert_equal collections(:uiuc_collection1), memberships.first.collection

    # change it
    unit.unit_collection_memberships.where(collection: collections(:uiuc_empty)).each do |m|
      m.update!(unit_default: true)
    end

    # assert the changes
    unit.reload
    memberships = unit.unit_collection_memberships.where(unit_default: true)
    assert_equal 1, memberships.count
    assert_equal collections(:uiuc_empty), memberships.first.collection
  end

end
