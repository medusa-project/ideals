require 'test_helper'

class BitstreamsControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    setup_s3
  end

  teardown do
    clear_message_queues
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southwest_unit1_collection1_item1)
    post item_bitstreams_path(item)
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    item = items(:southwest_unit1_collection1_item1)
    post item_bitstreams_path(item)
    assert_redirected_to item.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:northeast))
    item = items(:southwest_unit1_collection1_item1)
    post item_bitstreams_path(item),
         xhr: true,
         params: {
           bitstream: {
             filename: "new.jpg"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 201 for authorized users" do
    log_in_as(users(:southwest_admin))
    item = items(:southwest_unit1_collection1_item1)
    post item_bitstreams_path(item), params: {
      bitstream: {
        filename: "new.jpg",
        length:   123
      }
    }
    assert_response :created

    bs = Bitstream.order(created_at: :desc).limit(1).first
    assert_equal item_bitstream_url(bs.item, bs),
                 response.headers['Location']
  end

  test "create() creates a Bitstream" do
    log_in_as(users(:southwest_admin))
    item = items(:southwest_unit1_collection1_item1)
    assert_difference "Bitstream.count" do
      post item_bitstreams_path(item), params: {
        bitstream: {
          filename: "new.jpg",
          length:   123
        }
      }
    end
    bs = Bitstream.order(created_at: :desc).limit(1).first
    assert_equal "new.jpg", bs.filename
  end

  test "create() creates an associated Event" do
    log_in_as(users(:southwest_admin))
    item = items(:southwest_unit1_collection1_item1)
    assert_difference "Event.count", 1 do
      post item_bitstreams_path(item), params: {
        bitstream: {
          filename: "cats.jpg",
          length:   123
        }
      }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    item = items(:southwest_unit1_collection1_item1)
    post item_bitstreams_path(item), params: {
      bitstream: {
        bogus: "bogus"
      }
    }
    assert_response :bad_request
  end

  # data()

  test "data() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southwest_unit1_collection1_item1)
    bs   = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_data_path(item, bs)
    assert_response :not_found
  end

  test "data() returns HTTP 200 for bitstreams in staging" do
    fixture = file_fixture("pdf.pdf")
    item    = items(:southwest_unit1_collection1_item1)
    bs      = Bitstream.new_in_staging(item:     item,
                                       filename: "new_pdf.pdf",
                                       length:   File.size(fixture))
    bs.save!
    begin
      File.open(fixture, "r") do |file|
        bs.upload_to_staging(file)
      end
      get item_bitstream_data_path(item, bs)
      assert_response :ok
      assert_equal File.size(fixture), response.body.length
    ensure
      bs.delete_from_staging
    end
  end

  test "data() returns HTTP 200 for bitstreams in permanent storage" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)

    get item_bitstream_data_path(bs.item, bs)
    assert_response :ok
    assert_equal bs.length, response.body.length
  end

  test "data() returns HTTP 400 for an invalid range" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_data_path(bs.item, bs),
        headers: { Range: "bytes=#{bs.length}-#{bs.length + 100}"}
    assert_response :bad_request
  end

  test "data() returns HTTP 403 for embargoed items" do
    item = items(:southwest_unit1_collection1_embargoed)
    bs   = item.bitstreams.first

    get item_bitstream_data_path(item, bs)
    assert_response :forbidden
  end

  test "data() returns HTTP 403 for withdrawn items" do
    item = items(:southwest_unit1_collection1_withdrawn)
    bs   = item.bitstreams.first

    get item_bitstream_data_path(item, bs)
    assert_response :forbidden
  end

  test "data() returns HTTP 404 for missing bitstreams" do
    item = items(:southwest_unit1_collection1_item1)
    get item_bitstream_data_path(item, 9999999)
    assert_response :not_found
  end

  test "data() returns HTTP 404 when the underlying data is missing" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    bs.update!(permanent_key: nil)
    get item_bitstream_data_path(bs.item, bs)
    assert_response :not_found
  end

  test "data() respects role limits" do
    item = items(:southwest_unit1_collection1_withdrawn) # (an item that only sysadmins have access to)
    bs   = item.bitstreams.first

    # Assert that sysadmins can access it
    log_in_as(users(:southwest_sysadmin))
    get item_bitstream_data_path(item, bs)
    assert_response :ok

    # Assert that role-limited sysadmins can't
    get item_bitstream_data_path(item, bs, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  test "data() supports a response-content-disposition argument" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_data_path(bs.item, bs,
                                 "response-content-disposition": "inline")
    assert_equal "inline", response.header['Content-Disposition']
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    delete item_bitstreams_path(bs.item, bs)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    delete item_bitstream_path(bs.item, bs)
    assert_redirected_to bs.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    delete item_bitstream_path(bs.item, bs)
    assert_response :forbidden
  end

  test "destroy() returns HTTP 204 for an existing bitstream" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    delete item_bitstream_path(bs.item, bs)
    assert_response :no_content
  end

  test "destroy() destroys the bitstream" do
    log_in_as(users(:southwest_admin))
    assert_difference "Bitstream.count", -1 do
      bs = bitstreams(:southwest_unit1_collection1_item1_approved)
      delete item_bitstream_path(bs.item, bs)
    end
  end

  test "destroy() creates an associated Event" do
    log_in_as(users(:southwest_admin))
    assert_difference "Event.count", 1 do
      bs = bitstreams(:southwest_unit1_collection1_item1_approved)
      delete item_bitstream_path(bs.item, bs)
    end
  end

  test "destroy() returns HTTP 404 for a missing bitstream" do
    log_in_as(users(:southwest_admin))
    delete "/items/#{items(:southwest_unit1_collection1_item1).id}/bitstreams/999999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item      = items(:southwest_unit1_collection1_item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream)
    assert_response :not_found
  end

  test "edit() returns HTTP 403 for logged-out users" do
    item      = items(:southwest_unit1_collection1_item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    item      = items(:southwest_unit1_collection1_item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream), xhr: true
    assert_response :forbidden
  end

  test "edit() returns HTTP 404 for non-XHR requests" do
    log_in_as(users(:southwest_admin))
    item      = items(:southwest_unit1_collection1_item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream)
    assert_response :not_found
  end

  test "edit() returns HTTP 200 for XHR requests" do
    log_in_as(users(:southwest_admin))
    item      = items(:southwest_unit1_collection1_item1)
    bitstream = item.bitstreams.first
    get edit_item_bitstream_path(item, bitstream), xhr: true
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    item = items(:southwest_unit1_collection1_item1)
    get item_bitstreams_path(item)
    assert_response :not_found
  end

  test "index() with a non-zip format returns HTTP 415" do
    item = items(:southwest_unit1_collection1_item1)
    get item_bitstreams_path(item)
    assert_response :unsupported_media_type
  end

  test "index() with no results returns HTTP 204" do
    item = items(:southwest_unit1_collection1_item1)
    item.bitstreams.delete_all
    get item_bitstreams_path(item, format: :zip)
    assert_response :no_content
  end

  test "index() redirects to a Download" do
    item = items(:southwest_unit1_collection1_item1)
    get item_bitstreams_path(item, format: :zip)
    assert_response 302
  end

  test "index() ascribes a download event to all downloaded bitstreams" do
    item = items(:southwest_unit1_collection1_item1)
    item.bitstreams.each do |bs|
      assert_equal 0, bs.download_count
    end

    get item_bitstreams_path(item, format: :zip)
    # Normally we would expect all of the bitstreams to have had their download
    # count incremented, but index() may exclude some of them based on the
    # policy scope.
    total_dls = 0
    item.bitstreams.each do |bs|
      total_dls += bs.download_count
    end
    assert total_dls > 0
  end

  # ingest()

  test "ingest() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    post item_bitstream_ingest_path(bs.item, bs)
    assert_response :not_found
  end

  test "ingest() redirects to root page for logged-out users" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    post item_bitstream_ingest_path(bs.item, bs)
    assert_redirected_to bs.institution.scope_url
  end

  test "ingest() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    post item_bitstream_ingest_path(bs.item, bs)
    assert_response :forbidden
  end

  test "ingest() returns HTTP 400 if the bitstream's permanent key is nil" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    bs.update!(permanent_key: nil)
    post item_bitstream_ingest_path(bs.item, bs)
    assert_response :bad_request
  end

  test "ingest() returns HTTP 400 if the bitstream's item does not have a handle" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_submitting_1)
    item = bs.item
    item.handle&.destroy!
    post item_bitstream_ingest_path(item, bs)
    assert_response :bad_request
  end

  test "ingest() ingests the bitstream" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    bs.messages.destroy_all
    assert !bs.submitted_for_ingest?

    post item_bitstream_ingest_path(bs.item, bs)
    bs.reload
    assert bs.submitted_for_ingest?
  end

  test "ingest() returns HTTP 204 for a successful ingest" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    post item_bitstream_ingest_path(bs.item, bs)
    assert_response :no_content
  end

  test "ingest() returns HTTP 404 for a missing bitstream" do
    log_in_as(users(:southwest_admin))
    post "/items/#{items(:southwest_unit1_collection1_item1).id}/bitstreams/999999/ingest"
    assert_response :not_found
  end

  # object()

  test "object() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_object_path(bs.item, bs)
    assert_response :not_found
  end

  test "object() returns HTTP 307 for an existing bitstream with an existing
  storage object" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_object_path(bs.item, bs)
    assert_response :temporary_redirect
  end

  test "object() returns HTTP 404 for an existing bitstream with a nonexistent
  storage object" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    bs.update!(permanent_key: nil)

    get item_bitstream_object_path(bs.item, bs)
    assert_response :not_found
  end

  test "object() increments the bitstream's download count when dl is not
  provided" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_object_path(bs.item, bs)
    bs.reload
    assert_equal 1, bs.download_count
  end

  test "object() does not increment the bitstream's download count when
  dl=0" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_object_path(bs.item, bs, dl: 0)
    bs.reload
    assert_equal 0, bs.download_count
  end

  test "object() returns HTTP 403 for embargoed items" do
    item = items(:southwest_unit1_collection1_embargoed)
    bs   = item.bitstreams.first

    get item_bitstream_object_path(item, bs)
    assert_response :forbidden
  end

  test "object() returns HTTP 403 for withdrawn items" do
    item = items(:southwest_unit1_collection1_withdrawn)
    bs   = item.bitstreams.first

    get item_bitstream_object_path(item, bs)
    assert_response :forbidden
  end

  test "object() returns HTTP 404 for missing bitstreams" do
    item = items(:southwest_unit1_collection1_item1)
    get item_bitstream_object_path(item, 9999999)
    assert_response :not_found
  end

  test "object() supports a response-content-disposition argument" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)

    get item_bitstream_object_path(bs.item, bs,
                                   dl: 0,
                                   "response-content-disposition": "inline")
    follow_redirect!
    assert request.url.include?("response-content-disposition=inline")
  end

  test "object() respects role limits" do
    item = items(:southwest_unit1_collection1_withdrawn) # (an item that only sysadmins have access to)
    bs   = item.bitstreams.first

    # Assert that sysadmins can access it
    log_in_as(users(:southwest_sysadmin))
    get item_bitstream_object_path(item, bs)
    assert_response :temporary_redirect

    # Assert that role-limited sysadmins can't
    get item_bitstream_object_path(item, bs, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_path(bs.item, bs)
    assert_response :not_found
  end

  test "show() returns HTTP 200" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_path(bs.item, bs)
    assert_response :ok
  end

  test "show() returns HTTP 403 for embargoed items" do
    item = items(:southwest_unit1_collection1_embargoed)
    bs   = item.bitstreams.first

    get item_bitstream_path(item, bs)
    assert_response :forbidden
  end

  test "show() returns HTTP 403 for withdrawn items" do
    item = items(:southwest_unit1_collection1_withdrawn)
    bs   = item.bitstreams.first

    get item_bitstream_path(item, bs)
    assert_response :forbidden
  end

  test "show() with pdf format returns HTTP 200 for a native PDF" do
    bs = bitstreams(:southwest_unit1_collection1_item1_pdf)
    get item_bitstream_path(bs.item, bs, format: :pdf)
    assert_response :ok
  end

  test "show() with pdf format redirects for a bitstream that can be converted
  into PDF" do
    bs = bitstreams(:southwest_unit1_collection1_item1_doc)
    get item_bitstream_path(bs.item, bs, format: :pdf)
    assert_response :found
  end

  test "show() with pdf format returns HTTP 406 for a bitstream that cannot be
  represented as PDF" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_path(bs.item, bs, format: :pdf)
    assert_response :not_acceptable
  end

  test "show() respects role limits" do
    item = items(:southwest_unit1_collection1_withdrawn) # (an item that only sysadmins have access to)
    bs   = item.bitstreams.first

    # Assert that sysadmins can access it
    log_in_as(users(:southwest_sysadmin))
    get item_bitstream_path(item, bs)
    assert_response :ok

    # Assert that role-limited sysadmins can't
    get item_bitstream_path(item, bs, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    patch item_bitstream_path(bs.item, bs)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    patch item_bitstream_path(bs.item, bs)
    assert_redirected_to bs.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    patch item_bitstream_path(bs.item, bs)
    assert_response :forbidden
  end
  
  test "update() updates a bitstream" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    patch item_bitstream_path(bs.item, bs),
          xhr: true,
          params: {
              bitstream: {
                  role: Role::UNIT_ADMINISTRATOR
              }
          }
    bs.reload
    assert_equal Role::UNIT_ADMINISTRATOR, bs.role
  end

  test "update() creates an associated Event" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    assert_difference "Event.count" do
      patch item_bitstream_path(bs.item, bs),
            xhr: true,
            params: {
              bitstream: {
                role: Role::UNIT_ADMINISTRATOR
              }
            }
    end
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    patch item_bitstream_path(bs.item, bs),
          xhr: true,
          params: {
              bitstream: {
                  role: Role::UNIT_ADMINISTRATOR
              }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    patch item_bitstream_path(bs.item, bs),
          xhr: true,
          params: {
              bitstream: {
                  role: 9999
              }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent collections" do
    log_in_as(users(:southwest_admin))
    patch "/items/#{items(:southwest_unit1_collection1_item1).id}/bitstreams/bogus"
    assert_response :not_found
  end

  # viewer()

  test "viewer() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    patch item_bitstream_path(bs.item, bs)
    assert_response :not_found
  end

  test "viewer() returns HTTP 200" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_viewer_path(bs.item, bs), xhr: true
    assert_response :ok
  end

  test "viewer() returns HTTP 403 for embargoed items" do
    item = items(:southwest_unit1_collection1_embargoed)
    bs   = item.bitstreams.first

    get item_bitstream_viewer_path(item, bs), xhr: true
    assert_response :forbidden
  end

  test "viewer() returns HTTP 403 for withdrawn items" do
    item = items(:southwest_unit1_collection1_withdrawn)
    bs   = item.bitstreams.first

    get item_bitstream_viewer_path(item, bs), xhr: true
    assert_response :forbidden
  end

  test "viewer() returns HTTP 404 for non-XHR requests" do
    bs = bitstreams(:southwest_unit1_collection1_item1_approved)
    get item_bitstream_viewer_path(bs.item, bs)
    assert_response :not_found
  end

  test "viewer() respects role limits" do
    item = items(:southwest_unit1_collection1_withdrawn) # (an item that only sysadmins have access to)
    bs   = item.bitstreams.first

    # Assert that sysadmins can access it
    log_in_as(users(:southwest_sysadmin))
    get item_bitstream_viewer_path(item, bs), xhr: true
    assert_response :ok

    # Assert that role-limited sysadmins can't
    get item_bitstream_viewer_path(item, bs, role: Role::LOGGED_OUT), xhr: true
    assert_response :forbidden
  end

end
