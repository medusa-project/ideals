require 'test_helper'

class LdapQueryTest < ActiveSupport::TestCase

  test "is_member_of?() returns false when the given user is not a member of the given group" do
    skip "Not testable due to firewall restrictions"
    config = ::Configuration.instance
    group = config.admin[:ad_group]
    netid = "bogusbogus"
    assert !LdapQuery.new.is_member_of?(group, netid)
  end

  test "is_member_of?() returns true when the given user is a member of the given group" do
    skip "Not testable due to firewall restrictions"
    config = ::Configuration.instance
    group = config.admin[:ad_group]
    netid = config.admin[:tech_mail_list].find{ |e| e.end_with?("@illinois.edu") }.split("@").first
    assert LdapQuery.new.is_member_of?(group, netid)
  end


end