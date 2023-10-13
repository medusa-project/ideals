require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southeast)
    host! @institution.fqdn
    clear_message_queues
    setup_opensearch
    setup_s3
  end

  teardown do
    log_out
  end

  # approve()

  test "approve() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitted)
    patch item_approve_path(item)
    assert_response :not_found
  end

  test "approve() redirects to root page for logged-out users" do
    item = items(:southeast_submitted)
    patch item_approve_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "approve() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    item = items(:southeast_submitted)
    patch item_approve_path(item)
    assert_response :forbidden
  end

  test "approve() redirects to the item page for authorized users" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    patch item_approve_path(item)
    assert_redirected_to item_path(item)
  end

  test "approve() approves an item" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    patch item_approve_path(item)
    item.reload
    assert_equal Item::Stages::APPROVED, item.stage
  end

  test "approve() moves an item's bitstreams into permanent storage" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    patch item_approve_path(item)

    item.bitstreams.each do |bs|
      assert bs.permanent_key.present?
    end
  end

  test "approve() creates an associated handle" do
    item = items(:southeast_submitted)
    assert_nil item.handle
    log_in_as(users(:southeast_admin))
    patch item_approve_path(item)
    item.reload
    assert_not_nil item.handle
  end

  test "approve() sends an email to the submitter" do
    item = items(:southeast_submitted)
    assert ActionMailer::Base.deliveries.empty?
    log_in_as(users(:southeast_admin))
    patch item_approve_path(item)
    assert !ActionMailer::Base.deliveries.empty?
  end

  # bury()

  test "bury() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    post item_bury_path(item)
    assert_response :not_found
  end

  test "bury() redirects to root page for logged-out users" do
    item = items(:southeast_item1)
    post item_bury_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "bury() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    post item_bury_path(items(:southeast_item1))
    assert_response :forbidden
  end

  test "bury() buries the item" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitting)
    post item_bury_path(item)
    item.reload
    assert item.buried?
  end

  test "bury() returns HTTP 302 for an existing item" do
    log_in_as(users(:southeast_admin))
    submission = items(:southeast_item1)
    expected   = submission.primary_collection
    post item_bury_path(submission)
    assert_redirected_to expected
  end

  test "bury() returns HTTP 404 for a missing item" do
    log_in_as(users(:southeast_admin))
    post item_bury_path "/items/99999"
    assert_response :not_found
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    delete item_path(item)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    item = items(:southeast_item1)
    delete item_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    delete item_path(items(:southeast_item1))
    assert_response :forbidden
  end

  test "destroy() destroys the item" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitting)
    delete item_path(item)
    assert_raises ActiveRecord::RecordNotFound do
      item.reload
    end
  end

  test "destroy() returns HTTP 302 for an existing item" do
    log_in_as(users(:southeast_admin))
    submission = items(:southeast_item1)
    expected   = submission.primary_collection
    delete item_path(submission)
    assert_redirected_to expected
  end

  test "destroy() returns HTTP 404 for a missing item" do
    log_in_as(users(:southeast_admin))
    delete "/items/99999"
    assert_response :not_found
  end

  # download_counts()

  test "download_counts() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_download_counts_path(item)
    assert_response :not_found
  end

  test "download_counts() redirects to root page for logged-out users" do
    item = items(:southeast_item1)
    get item_download_counts_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "download_counts() returns HTTP 200 for HTML" do
    log_in_as(users(:southeast_admin))
    get item_download_counts_path(items(:southeast_item1),
                                  from_year:  2022,
                                  from_month: 1,
                                  to_year:    2022,
                                  to_month:   2)
    assert_response :ok
  end

  test "download_counts() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southeast_admin))
    get item_download_counts_path(items(:southeast_item1),
                                  from_year:  2023,
                                  from_month: 2,
                                  to_year:    2022,
                                  to_month:   2,
                                  format:     :csv)
    assert_response :bad_request
  end

  test "download_counts() returns HTTP 200 for CSV" do
    log_in_as(users(:southeast_admin))
    get item_download_counts_path(items(:southeast_item1),
                                  from_year:  2022,
                                  from_month: 1,
                                  to_year:    2022,
                                  to_month:   2,
                                  format:     :csv)
    assert_response :ok
  end

  # edit_embargoes()

  test "edit_embargoes() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_edit_embargoes_path(item), xhr: true
    assert_response :not_found
  end

  test "edit_embargoes() returns HTTP 403 for logged-out users" do
    item = items(:southeast_item1)
    get item_edit_embargoes_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_embargoes() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item = items(:southeast_item1)
    get item_edit_embargoes_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_embargoes() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    item = items(:southeast_item1)
    get item_edit_embargoes_path(item)
    assert_response :not_found
  end

  test "edit_embargoes() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_item1)
    get item_edit_embargoes_path(item), xhr: true
    assert_response :ok
  end

  # edit_membership()

  test "edit_membership() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_edit_membership_path(item), xhr: true
    assert_response :not_found
  end

  test "edit_membership() returns HTTP 403 for logged-out users" do
    item = items(:southeast_item1)
    get item_edit_membership_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_membership() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item = items(:southeast_item1)
    get item_edit_membership_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_membership() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    item = items(:southeast_item1)
    get item_edit_membership_path(item)
    assert_response :not_found
  end

  test "edit_membership() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_item1)
    get item_edit_membership_path(item), xhr: true
    assert_response :ok
  end

  # edit_metadata()

  test "edit_metadata() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_edit_metadata_path(item), xhr: true
    assert_response :not_found
  end

  test "edit_metadata() returns HTTP 403 for logged-out users" do
    item = items(:southeast_item1)
    get item_edit_metadata_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_metadata() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item = items(:southeast_item1)
    get item_edit_metadata_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_metadata() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    item = items(:southeast_item1)
    get item_edit_metadata_path(item)
    assert_response :not_found
  end

  test "edit_metadata() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_item1)
    get item_edit_metadata_path(item), xhr: true
    assert_response :ok
  end

  # edit_properties()

  test "edit_properties() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_edit_properties_path(item), xhr: true
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 403 for logged-out users" do
    item = items(:southeast_item1)
    get item_edit_properties_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item = items(:southeast_item1)
    get item_edit_properties_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_properties() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    item = items(:southeast_item1)
    get item_edit_properties_path(item)
    assert_response :not_found
  end

  test "edit_properties() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_item1)
    get item_edit_properties_path(item), xhr: true
    assert_response :ok
  end

  # edit_withdrawal()

  test "edit_withdrawal() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_edit_withdrawal_path(item), xhr: true
    assert_response :not_found
  end

  test "edit_withdrawal() returns HTTP 403 for logged-out users" do
    item = items(:southeast_item1)
    get item_edit_withdrawal_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_withdrawal() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item = items(:southeast_item1)
    get item_edit_withdrawal_path(item), xhr: true
    assert_response :forbidden
  end

  test "edit_withdrawal() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    item = items(:southeast_item1)
    get item_edit_withdrawal_path(item)
    assert_response :not_found
  end

  test "edit_withdrawal() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_item1)
    get item_edit_withdrawal_path(item), xhr: true
    assert_response :ok
  end

  # exhume()

  test "exhume() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_buried)
    post item_exhume_path(item)
    assert_response :not_found
  end

  test "exhume() redirects to root page for logged-out users" do
    item = items(:southeast_buried)
    post item_exhume_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "exhume() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    post item_exhume_path(items(:southeast_buried))
    assert_response :forbidden
  end

  test "exhume() buries the item" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_buried)
    post item_exhume_path(item)
    item.reload
    assert !item.buried?
  end

  test "exhume() returns HTTP 302 for an existing item" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_buried)
    post item_exhume_path(item)
    assert_redirected_to item
  end

  test "exhume() returns HTTP 404 for a missing item" do
    log_in_as(users(:southeast_admin))
    post "/items/99999/exhume"
    assert_response :not_found
  end

  # export()

  test "export() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get export_items_path
    assert_response :not_found
  end

  test "export() via GET redirects to root page for logged-out users" do
    get export_items_path
    assert_redirected_to @institution.scope_url
  end

  test "export() via GET returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    get export_items_path
    assert_response :forbidden
  end

  test "export() via GET returns HTTP 200 for authorized users" do
    log_in_as(users(:southeast_admin))
    get export_items_path
    assert_response :ok
  end

  test "export() via POST returns HTTP 400 for an empty handles argument" do
    log_in_as(users(:southeast_admin))
    post export_items_path, params: {
      handles: "",
      elements: ["dc:title"]
    }
    assert_response :bad_request
  end

  test "export() via POST returns HTTP 400 for an empty elements argument" do
    log_in_as(users(:southeast_admin))
    post export_items_path, params: {
      handles: "1/2",
      elements: []
    }
    assert_response :bad_request
  end

  test "export() via POST returns HTTP 400 for an invalid handles argument" do
    log_in_as(users(:southeast_admin))
    post export_items_path, params: {
      handles: "bogus/3",
      elements: ["dc:title"]
    }
    assert_response :bad_request
  end

  test "export() via POST returns HTTP 400 for handles that are not unit or
  collection handles" do
    log_in_as(users(:southeast_admin))
    handle = handles(:southeast_item1)
    post export_items_path, params: {
      handles: handle.handle,
      elements: ["dc:title"]
    }
    assert_response :bad_request
  end

  test "export() via POST exports CSV" do
    log_in_as(users(:southeast_admin))
    post export_items_path, params: {
      handles: handles(:southeast_collection1).handle,
      elements: ["dc:title"]
    }
    assert response.body.start_with?("id,")
  end

  test "export() via POST does not include content from other institutions" do
    log_in_as(users(:southeast_admin))
    post export_items_path, params: {
      handles: handles(:southwest_unit1_collection1).handle,
      elements: ["dc:title"]
    }
    assert_response :forbidden
  end

  # file_navigator()

  test "file_navigator() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get item_file_navigator_path(items(:southeast_item1)), xhr: true
    assert_response :not_found
  end

  test "file_navigator() returns HTTP 200 for XHR requests" do
    get item_file_navigator_path(items(:southeast_item1)), xhr: true
    assert_response :ok
  end

  test "file_navigator() returns HTTP 404 for non-XHR requests" do
    get item_file_navigator_path(items(:southeast_item1))
    assert_response :not_found
  end

  test "file_navigator() returns HTTP 403 for submitting items" do
    get item_file_navigator_path(items(:southeast_submitting)), xhr: true
    assert_response :forbidden
  end

  test "file_navigator() returns HTTP 403 for embargoed items" do
    get item_file_navigator_path(items(:southeast_embargoed)), xhr: true
    assert_response :forbidden
  end

  test "file_navigator() returns HTTP 410 for withdrawn items" do
    get item_file_navigator_path(items(:southeast_withdrawn)), xhr: true
    assert_response :gone
  end

  test "file_navigator() returns HTTP 410 for buried items" do
    get item_file_navigator_path(items(:southeast_buried)), xhr: true
    assert_response :gone
  end

  # index()

  test "index() returns HTTP 200 for HTML" do
    get items_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for JSON" do
    get items_path(format: :json)
    assert_response :ok
  end

  test "index() returns HTTP 200 in global scope" do
    host! ::Configuration.instance.main_host
    get items_path
    assert_response :ok
  end

  test "index() omits submitting, submitted, embargoed, withdrawn, and buried
  items by default" do
    skip # TODO: this fails intermittently
    Item.reindex_all
    OpenSearchClient.instance.refresh

    expected_count = Item.non_embargoed.
        where.not(stage: [Item::Stages::SUBMITTING,
                          Item::Stages::SUBMITTED,
                          Item::Stages::WITHDRAWN,
                          Item::Stages::BURIED]).
        count

    get items_path(format: :json)
    struct = JSON.parse(response.body)
    assert_equal expected_count, struct['numResults']
  end

  # process_review()

  test "process_review() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post process_review_items_path
    assert_response :not_found
  end

  test "process_review() redirects to root page for logged-out users" do
    post process_review_items_path
    assert_redirected_to @institution.scope_url
  end

  test "process_review() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    post process_review_items_path
    assert_response :forbidden
  end

  test "process_review() redirects to the review page for authorized users" do
    log_in_as(users(:southeast_admin))
    post process_review_items_path
    assert_redirected_to review_items_path
  end

  test "process_review() approves items" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    post process_review_items_path,
         params: {
             items: [item.id],
             verb: "approve"
         }
    assert_redirected_to review_items_path
    item.reload
    assert_equal Item::Stages::APPROVED, item.stage
  end

  test "process_review() creates an associated handle for approved items" do
    item = items(:southeast_submitted)
    assert_nil item.handle
    log_in_as(users(:southeast_admin))
    post process_review_items_path,
         params: {
             items: [item.id],
             verb: "approve"
         }
    item.reload
    assert_not_nil item.handle
  end

  test "process_review() rejects items" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    post process_review_items_path,
         params: {
             items: [item.id],
             verb: "reject"
         }
    assert_redirected_to review_items_path
    item.reload
    assert_equal Item::Stages::REJECTED, item.stage
  end

  # recent()

  test "recent() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get recent_items_path
    assert_response :not_found
  end

  test "recent() returns HTTP 200" do
    get recent_items_path
    assert_response :ok
  end

  # reject()

  test "reject() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitted)
    patch item_reject_path(item)
    assert_response :not_found
  end

  test "reject() redirects to root page for logged-out users" do
    item = items(:southeast_submitted)
    patch item_reject_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "reject() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    item = items(:southeast_submitted)
    patch item_reject_path(item)
    assert_response :forbidden
  end

  test "reject() redirects to the item page for authorized users" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    patch item_reject_path(item)
    assert_redirected_to item_path(item)
  end

  test "reject() rejects an item" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    patch item_reject_path(item)
    item.reload
    assert_equal Item::Stages::REJECTED, item.stage
  end

  test "reject() sends an email to the submitter" do
    item = items(:southeast_submitted)
    assert ActionMailer::Base.deliveries.empty?
    log_in_as(users(:southeast_admin))
    patch item_reject_path(item)
    assert !ActionMailer::Base.deliveries.empty?
  end

  # review()

  test "review() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get review_items_path
    assert_response :not_found
  end

  test "review() redirects to root page for logged-out users" do
    get review_items_path
    assert_redirected_to @institution.scope_url
  end

  test "review() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    get review_items_path
    assert_response :forbidden
  end

  test "review() returns HTTP 200" do
    log_in_as(users(:southeast_admin))
    get review_items_path
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get item_path(items(:southeast_item1))
    assert_response :not_found
  end

  test "show() returns HTTP 200" do
    get item_path(items(:southeast_item1))
    assert_response :ok
  end

  test "show() returns HTTP 200 for JSON" do
    get item_path(items(:southeast_item1), format: :json)
    assert_response :ok
  end

  test "show() redirects for an item in another institution for non-sysadmins" do
    item = items(:southwest_unit1_collection1_item1)
    get item_path(item)
    assert_redirected_to "http://" + item.institution.fqdn + item_path(item)
  end

  test "show() does not redirect for an item in another institution for
  sysadmins" do
    log_in_as(users(:southeast_sysadmin))
    item = items(:southwest_unit1_collection1_item1)
    get item_path(item)
    assert_response :ok
  end

  test "show() returns HTTP 403 for submitting items for unauthorized users" do
    get item_path(items(:southeast_submitting))
    assert_response :forbidden
  end

  test "show() redirects to the edit-submission page for submitting items for
  institution admins" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitting)
    get item_path(item)
    assert_redirected_to edit_submission_path(item)
  end

  test "show() returns HTTP 403 for embargoed items" do
    get item_path(items(:southeast_embargoed))
    assert_response :forbidden
  end

  test "show() returns HTTP 410 for withdrawn items" do
    get item_path(items(:southeast_withdrawn))
    assert_response :gone
  end

  test "show() returns HTTP 410 for buried items" do
    get item_path(items(:southeast_buried))
    assert_response :gone
  end

  test "show() respects role limits" do
    log_in_as(users(:southeast_admin))
    get item_path(items(:southeast_item1))
    assert_select("dl.properties")

    get item_path(items(:southeast_item1), role: Role::LOGGED_OUT)
    assert_select("dl.properties", false)
  end

  # statistics()

  test "statistics() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_statistics_path(item), xhr: true
    assert_response :not_found
  end

  test "statistics() returns HTTP 403 for logged-out users" do
    item = items(:southeast_item1)
    get item_statistics_path(item), xhr: true
    assert_response :forbidden
  end

  test "statistics() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    get item_statistics_path(items(:southeast_item1))
    assert_response :not_found
  end

  test "statistics() returns HTTP 200" do
    log_in_as(users(:southeast_admin))
    get item_statistics_path(items(:southeast_item1)), xhr: true
    assert_response :ok
  end

  # update()

  # TODO: write update() tests

  # upload_bitstreams()

  test "upload_bitstreams() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_item1)
    get item_upload_bitstreams_path(item), xhr: true
    assert_response :not_found
  end

  test "upload_bitstreams() returns HTTP 403 for logged-out users" do
    item = items(:southeast_item1)
    get item_upload_bitstreams_path(item), xhr: true
    assert_response :forbidden
  end

  test "upload_bitstreams() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item = items(:southeast_item1)
    get item_upload_bitstreams_path(item), xhr: true
    assert_response :forbidden
  end

  test "upload_bitstreams() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_sysadmin))
    item = items(:southeast_item1)
    get item_upload_bitstreams_path(item)
    assert_response :not_found
  end

  test "upload_bitstreams() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_item1)
    get item_upload_bitstreams_path(item), xhr: true
    assert_response :ok
  end

  # withdraw()

  test "withdraw() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southeast_submitted)
    patch item_withdraw_path(item)
    assert_response :not_found
  end

  test "withdraw() redirects to root page for logged-out users" do
    item = items(:southeast_submitted)
    patch item_withdraw_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "withdraw() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southeast))
    item = items(:southeast_submitted)
    patch item_withdraw_path(item)
    assert_response :forbidden
  end

  test "withdraw() redirects to the item page for authorized users" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    patch item_withdraw_path(item)
    assert_redirected_to item_path(item)
  end

  test "withdraw() withdraws an item" do
    log_in_as(users(:southeast_admin))
    item = items(:southeast_submitted)
    patch item_withdraw_path(item)
    item.reload
    assert_equal Item::Stages::WITHDRAWN, item.stage
  end

end
