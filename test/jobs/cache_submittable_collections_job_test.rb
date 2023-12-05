require 'test_helper'

class CacheSubmittableCollectionsJobTest < ActiveSupport::TestCase

  test "perform() creates a correct Task" do
    user = users(:southwest_shibboleth)

    CacheSubmittableCollectionsJob.perform_now(user:            user,
                                               client_ip:       "127.0.0.1",
                                               client_hostname: "localhost")

    task = Task.all.order(created_at: :desc).limit(1).first
    assert_equal "CacheSubmittableCollectionsJob", task.name
    assert_equal user, task.user
    assert !task.indeterminate
    assert_equal user.institution, task.institution
    assert_equal "Caching submittable collections for user #{user.email}",
                 task.status_text
  end

  test "perform() associates submittable Collections with the User" do
    user       = users(:southwest_shibboleth)
    collection = collections(:southwest_unit1_collection1)
    collection.submitting_users << user
    collection.save!
    collection = collections(:southwest_unit1_collection2)
    collection.submitting_users << user
    collection.save!

    CacheSubmittableCollectionsJob.perform_now(user:            user,
                                               client_ip:       "127.0.0.1",
                                               client_hostname: "localhost")
    assert_equal 2, user.cached_submittable_collections.count
  end

  test "perform() sets submittable_collections_cached_at" do
    user = users(:southwest_shibboleth)

    CacheSubmittableCollectionsJob.perform_now(user:            user,
                                               client_ip:       "127.0.0.1",
                                               client_hostname: "localhost")
    assert Time.now - user.submittable_collections_cached_at < 10.seconds
  end

  test "perform() nullifies caching_submittable_collections_task_id when
  complete" do
    user = users(:southwest_shibboleth)

    CacheSubmittableCollectionsJob.perform_now(user:            user,
                                               client_ip:       "127.0.0.1",
                                               client_hostname: "localhost")
    assert_nil user.caching_submittable_collections_task_id
  end

end
