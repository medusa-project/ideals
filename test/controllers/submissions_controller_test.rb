require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southeast)
    host! @institution.fqdn
    setup_opensearch
    setup_s3
  end

  teardown do
    log_out
  end

  # complete()

  test "complete() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitting)
    post submission_complete_path(item)
    assert_response :not_found
  end

  test "complete() redirects to root page for logged-out users" do
    item = items(:southeast_submitting)
    post submission_complete_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "complete() returns HTTP 302 for logged-in users" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to submission_status_path(item)
  end

  test "complete() redirects to the item when it has already been submitted" do
    item = items(:southeast_item1)
    assert !item.submitting?
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to item_path(item)
  end

  test "complete() redirects to the edit-submission form when the item is
  missing any required metadata fields" do
    item = items(:southeast_submitting)
    item.elements.destroy_all
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to edit_submission_path(item)
  end

  test "complete() redirects to the edit-submission form when the item has no
  associated bitstreams" do
    item = items(:southeast_submitting)
    item.bitstreams.destroy_all
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to edit_submission_path(item)
  end

  test "complete() redirects to the item when its collection is not reviewing
  submissions" do
    item = items(:southeast_submitting)
    item.primary_collection.update!(submissions_reviewed: false)

    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to item
  end

  test "complete() redirects to the submission status page when its collection
  is reviewing submissions" do
    item = items(:southeast_submitting)
    item.primary_collection.update!(submissions_reviewed: true)

    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to submission_status_path(item)
  end

  test "complete() updates the item's stage attribute" do
    item = items(:southeast_submitting)
    assert item.submitting?
    log_in_as(item.submitter)
    post submission_complete_path(item)

    item.reload
    assert_equal item.primary_collection&.submissions_reviewed ?
                   Item::Stages::SUBMITTED : Item::Stages::APPROVED,
                 item.stage
  end

  test "complete() does not attach an embargo when the open radio is selected" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    item.update!(temp_embargo_type:       "open",
                 temp_embargo_kind:       Embargo::Kind::DOWNLOAD)
    post submission_complete_path(item)

    item.reload
    assert_nil item.temp_embargo_kind
    assert_nil item.temp_embargo_type
    assert_nil item.temp_embargo_expires_at
    assert_nil item.temp_embargo_reason
    assert item.embargoes.empty?
  end

  test "complete() attaches a correct embargo when the institution-only radio
  is selected" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    item.update!(temp_embargo_type:       "institution",
                 temp_embargo_kind:       Embargo::Kind::DOWNLOAD,
                 temp_embargo_expires_at: "2053-01-01",
                 temp_embargo_reason:     "Test reason")
    post submission_complete_path(item)

    item.reload
    assert_nil item.temp_embargo_kind
    assert_nil item.temp_embargo_type
    assert_nil item.temp_embargo_expires_at
    assert_nil item.temp_embargo_reason
    assert_equal 1, item.embargoes.length
    embargo = item.embargoes.first
    assert_equal Embargo::Kind::DOWNLOAD, embargo.kind
    assert_equal Time.parse("2053-01-01"), embargo.expires_at
    assert_equal "Test reason", embargo.reason
    assert_equal 1, embargo.user_groups.length
    assert_equal "southeast", embargo.user_groups.first.key
  end

  test "complete() attaches a correct Embargo when the closed radio is selected" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    item.update!(temp_embargo_type:       "closed",
                 temp_embargo_kind:       Embargo::Kind::DOWNLOAD,
                 temp_embargo_expires_at: "2053-01-01",
                 temp_embargo_reason:     "Test reason")
    post submission_complete_path(item)

    item.reload
    assert_nil item.temp_embargo_kind
    assert_nil item.temp_embargo_type
    assert_nil item.temp_embargo_expires_at
    assert_nil item.temp_embargo_reason
    assert_equal 1, item.embargoes.length
    embargo = item.embargoes.first
    assert_equal Embargo::Kind::DOWNLOAD, embargo.kind
    assert_equal Time.parse("2053-01-01"), embargo.expires_at
    assert_equal "Test reason", embargo.reason
    assert embargo.user_groups.empty?
  end

  test "complete() attaches a correct embargo when the hide records checkbox is
  checked" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    item.update!(temp_embargo_type:       "closed",
                 temp_embargo_kind:       Embargo::Kind::ALL_ACCESS,
                 temp_embargo_expires_at: "2053-01-01",
                 temp_embargo_reason:     "Test reason")
    post submission_complete_path(item)

    item.reload
    assert_nil item.temp_embargo_kind
    assert_nil item.temp_embargo_type
    assert_nil item.temp_embargo_expires_at
    assert_nil item.temp_embargo_reason
    assert_equal 1, item.embargoes.length
    embargo = item.embargoes.first
    assert_equal Embargo::Kind::ALL_ACCESS, embargo.kind
    assert_equal Time.parse("2053-01-01"), embargo.expires_at
    assert_equal "Test reason", embargo.reason
    assert embargo.user_groups.empty?
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post submissions_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post submissions_path
    assert_redirected_to @institution.scope_url
  end

  test "create() creates an item" do
    log_in_as(users(:southeast))
    assert_difference "Item.count" do
      post submissions_path
      item = Item.order(created_at: :desc).first
      assert item.submitting?
    end
  end

  test "create() redirects to item-edit view" do
    log_in_as(users(:southeast))
    post submissions_path
    submission = Item.order(created_at: :desc).limit(1).first
    assert_redirected_to edit_submission_path(submission)
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitting)
    delete submission_path(item)
    assert_response :not_found
  end

  test "destroy() redirects to the item's owning institution for logged-out
  users" do
    item = items(:southeast_submitting)
    delete submission_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast2))
    delete submission_path(items(:southeast_submitting))
    assert_response :forbidden
  end

  test "destroy() redirects to the item's owning institution for an existing
  item" do
    log_in_as(users(:southeast))
    submission = items(:southeast_submitting)
    delete submission_path(submission)
    assert_redirected_to submission.institution.scope_url
  end

  test "destroy() returns HTTP 404 for a missing item" do
    log_in_as(users(:southeast))
    delete "/submissions/99999"
    assert_response :not_found
  end

  test "destroy() returns HTTP 403 when an item has already been submitted" do
    item = items(:southeast_item1)
    log_in_as(item.submitter)
    delete submission_path(item)
    assert_response :forbidden
  end

  test "destroy() buries the item" do
    log_in_as(users(:southeast))
    item = items(:southeast_submitting)
    delete submission_path(item)
    item.reload
    assert_equal Item::Stages::BURIED, item.stage
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitting)
    get edit_submission_path(item)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    item = items(:southeast_submitting)
    get edit_submission_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "edit() returns HTTP 200 for logged-in users" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    get edit_submission_path(item)
    assert_response :ok
  end

  test "edit() redirects to the item when an item has already been submitted" do
    item = items(:southeast_item1)
    log_in_as(item.submitter)
    get edit_submission_path(item)
    assert_redirected_to item_path(item)
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get submit_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get submit_path
    assert_redirected_to @institution.scope_url
  end

  test "new() returns HTTP 200 for logged-in users" do
    log_in_as(users(:southeast))
    get submit_path
    assert_response :ok
  end

  # status()

  test "status() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitted)
    get submission_status_path(item)
    assert_response :not_found
  end

  test "status() redirects to root page for logged-out users" do
    item = items(:southeast_submitted)
    get submission_status_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "status() returns HTTP 200 for logged-in users" do
    item = items(:southeast_submitted)
    log_in_as(item.submitter)
    get submission_status_path(item)
    assert_response :ok
  end

  test "status() redirects to the item when it is not in the submitted stage" do
    item = items(:southeast_item1)
    log_in_as(item.submitter)
    get submission_status_path(item)
    assert_redirected_to item_path(item)
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitting)
    patch submission_path(item)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    item = items(:southeast_submitting)
    patch submission_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item = items(:southeast_submitting)
    patch submission_path(item), xhr: true
    assert_response :forbidden
  end

  test "update() updates an item" do
    collection = collections(:southeast_empty)
    item       = items(:southeast_submitting)
    log_in_as(item.submitter)
    patch submission_path(item),
          xhr: true,
          params: {
              item: {
                  primary_collection_id: collection.id
              }
          }
    item.reload
    assert_equal collection.id, item.primary_collection.id
  end

  test "update() returns HTTP 204" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    patch submission_path(item),
          xhr: true,
          params: {
              item: {
                  primary_collection_id: collections(:southeast_empty).id
              }
          }
    assert_response :no_content
  end

  test "update() returns HTTP 400 for illegal arguments" do
    item = items(:southeast_submitting)
    log_in_as(item.submitter)
    patch submission_path(item),
          xhr: true,
          params: {
              item: {
                  primary_collection_id: 99999
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent items" do
    log_in_as(users(:southeast))
    patch "/submissions/bogus"
    assert_response :not_found
  end

  test "update() returns HTTP 403 when an item has already been submitted" do
    item = items(:southeast_item1)
    log_in_as(item.submitter)
    patch submission_path(item)
    assert_response :forbidden
  end

end
