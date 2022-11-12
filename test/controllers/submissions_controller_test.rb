require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    setup_opensearch
    setup_s3
  end

  teardown do
    log_out
  end

  # complete()

  test "complete() redirects to login page for logged-out users" do
    item = items(:uiuc_submitting)
    post submission_complete_path(item)
    assert_redirected_to login_path
  end

  test "complete() returns HTTP 302 for logged-in users" do
    item = items(:uiuc_submitting)
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to submission_status_path(item)
  end

  test "complete() returns HTTP 302 when an item has already been submitted" do
    item = items(:uiuc_item1)
    assert !item.submitting?
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to root_path
  end

  test "complete() redirects to the edit-submission form when the item is
  missing any required metadata fields" do
    item = items(:uiuc_submitting)
    item.elements.destroy_all
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to edit_submission_path(item)
  end

  test "complete() redirects to the edit-submission form when the item has no
  associated bitstreams" do
    item = items(:uiuc_submitting)
    item.bitstreams.destroy_all
    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to edit_submission_path(item)
  end

  test "complete() redirects to the item when its collection is not reviewing
  submissions" do
    item = items(:uiuc_submitting)
    item.primary_collection.update!(submissions_reviewed: false)

    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to item
  end

  test "complete() redirects to the submission status page when its collection
  is reviewing submissions" do
    item = items(:uiuc_submitting)
    item.primary_collection.update!(submissions_reviewed: true)

    log_in_as(item.submitter)
    post submission_complete_path(item)
    assert_redirected_to submission_status_path(item)
  end

  test "complete() updates the item's stage attribute" do
    item = items(:uiuc_submitting)
    assert item.submitting?
    log_in_as(item.submitter)
    post submission_complete_path(item)

    item.reload
    assert_equal item.primary_collection&.submissions_reviewed ?
                   Item::Stages::SUBMITTED : Item::Stages::APPROVED,
                 item.stage
  end

  test "complete() does not attach an embargo when the open radio is selected" do
    item = items(:uiuc_submitting)
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
    item = items(:uiuc_submitting)
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
    assert_equal "uiuc", embargo.user_groups.first.key
  end

  test "complete() attaches a correct Embargo when the closed radio is selected" do
    item = items(:uiuc_submitting)
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
    item = items(:uiuc_submitting)
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

  test "create() redirects to login page for logged-out users" do
    post submissions_path
    assert_redirected_to login_path
  end

  test "create() creates an item" do
    log_in_as(users(:local_sysadmin))
    assert_difference "Item.count" do
      post submissions_path
      item = Item.order(created_at: :desc).first
      assert item.submitting?
    end
  end

  test "create() redirects to item-edit view" do
    log_in_as(users(:local_sysadmin))
    post submissions_path
    submission = Item.order(created_at: :desc).limit(1).first
    assert_redirected_to edit_submission_path(submission)
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete submission_path(items(:uiuc_submitting))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete submission_path(items(:uiuc_submitting))
    assert_response :forbidden
  end

  test "destroy() destroys the item" do
    log_in_as(users(:local_sysadmin))
    item = items(:uiuc_submitting)
    assert_difference "Item.count", -1 do
      delete submission_path(item)
    end
  end

  test "destroy() returns HTTP 302 for an existing item" do
    log_in_as(users(:local_sysadmin))
    submission = items(:uiuc_submitting)
    delete submission_path(submission)
    assert_redirected_to root_path
  end

  test "destroy() returns HTTP 404 for a missing item" do
    log_in_as(users(:local_sysadmin))
    delete "/submissions/99999"
    assert_response :not_found
  end

  test "destroy() redirects back when an item has already been submitted" do
    log_in_as(users(:local_sysadmin))
    item = items(:uiuc_item1)
    delete submission_path(item)
    assert_redirected_to root_url
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    item = items(:uiuc_submitting)
    get edit_submission_path(item)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 200 for logged-in users" do
    item = items(:uiuc_submitting)
    log_in_as(item.submitter)
    get edit_submission_path(item)
    assert_response :ok
  end

  test "edit() redirects back when an item has already been submitted" do
    item = items(:uiuc_item1)
    log_in_as(item.submitter)
    get edit_submission_path(item)
    assert_redirected_to root_path
  end

  # new()

  test "new() redirects to login page for logged-out users" do
    get submit_path
    assert_redirected_to login_path
  end

  test "new() returns HTTP 200 for logged-in users" do
    log_in_as(users(:norights))
    get submit_path
    assert_response :ok
  end

  # status()

  test "status() redirects to login page for logged-out users" do
    item = items(:uiuc_submitted)
    get submission_status_path(item)
    assert_redirected_to login_path
  end

  test "status() returns HTTP 200 for logged-in users" do
    item = items(:uiuc_submitted)
    log_in_as(item.submitter)
    get submission_status_path(item)
    assert_response :ok
  end

  test "status() redirects back when an item is not in the submitted stage" do
    item = items(:uiuc_item1)
    log_in_as(item.submitter)
    get submission_status_path(item)
    assert_redirected_to root_path
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    item = items(:uiuc_submitting)
    patch submission_path(item)
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    item = items(:uiuc_submitting)
    patch submission_path(item)
    assert_response :forbidden
  end

  test "update() updates an item" do
    log_in_as(users(:local_sysadmin))
    collection = collections(:uiuc_empty)
    item       = items(:uiuc_submitting)
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
    log_in_as(users(:local_sysadmin))
    item = items(:uiuc_submitting)
    patch submission_path(item),
          xhr: true,
          params: {
              item: {
                  primary_collection_id: collections(:uiuc_empty).id
              }
          }
    assert_response :no_content
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    item = items(:uiuc_submitting)
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
    log_in_as(users(:local_sysadmin))
    patch "/submissions/bogus"
    assert_response :not_found
  end

  test "update() redirects back when an item has already been submitted" do
    log_in_as(users(:local_sysadmin))
    item = items(:uiuc_item1)
    patch submission_path(item)
    assert_redirected_to root_url
  end

end
