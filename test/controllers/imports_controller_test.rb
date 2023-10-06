require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    @bulkfile = fixture_file_upload(file_fixture("escher_lego.png"), 'image/jpeg')
    @import   = imports(:southwest_saf_new)
    setup_s3
  end

  teardown do
    @import.delete_file
  end

  # complete_upload()

  test "complete_upload() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    log_in_as(users(:southwest))
    post import_complete_upload_path(@import)
    assert_response :not_found
  end

  test "complete_upload() redirects to root page for logged-out users" do
    post "/imports/99999/complete-upload"
    assert_redirected_to @import.institution.scope_url
  end

  test "complete_upload() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    post import_complete_upload_path(@import)
    assert_response :forbidden
  end

  test "complete_upload() invokes an ImportJob" do
    skip # TODO: why doesn't the job run?
    log_in_as(users(:southwest_admin))
    assert_difference "Item.count" do
      package_root = File.join(file_fixture_path, "/packages/csv")
      csv_package  = File.join(Dir.tmpdir, "test.zip")
      `cd "#{package_root}" && rm -f #{csv_package} && zip -r "#{csv_package}" valid_items`
      @import.update!(filename: File.basename(csv_package),
                      length:   File.size(csv_package))
      ObjectStore.instance.put_object(key:  @import.file_key,
                                      path: csv_package)

      post import_complete_upload_path(@import)
    end
  end

  test "complete_upload() returns HTTP 204 upon success" do
    log_in_as(users(:southwest_admin))
    post import_complete_upload_path(@import)
    assert_response :no_content
  end

  test "complete_upload() returns HTTP 404 for nonexistent imports" do
    log_in_as(users(:southwest_admin))
    post "/imports/99999/complete-upload"
    assert_response :not_found
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post imports_path, xhr: true
    assert_response :not_found
  end

  test "create() returns HTTP 403 for logged-out users" do
    post imports_path, xhr: true
    assert_response :forbidden
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    post imports_path, xhr: true,
         params: {
           import: {
             collection_id: ""
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    post imports_path,
         xhr: true,
         params: {
           import: {
             collection_id: ""
           }
         }
    assert_response :bad_request
  end

  test "create() returns HTTP 200" do
    user = users(:southwest_admin)
    log_in_as(user)
    post imports_path,
         xhr: true,
         params: {
           import: {
             institution_id: institutions(:southwest).id,
             collection_id:  collections(:southwest_unit1_collection1).id
           }
         }
    assert_response :ok
  end

  test "create() creates a correct instance" do
    user = users(:southwest_admin)
    log_in_as(user)
    assert_difference "Import.count" do
      post imports_path,
           xhr: true,
           params: {
             import: {
               institution_id: institutions(:southwest).id,
               collection_id:  collections(:southwest_unit1_collection1).id
             }
           }
    end
    import = Import.order(created_at: :desc).limit(1).first
    assert_equal user.institution, import.institution
    assert_equal user, import.user
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get edit_import_path(@import)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    get edit_import_path(@import)
    assert_redirected_to @import.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get edit_import_path(@import)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get edit_import_path(@import)
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get imports_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get imports_path
    assert_redirected_to @import.institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get imports_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get imports_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get imports_path
    assert_response :ok

    get imports_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_import_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_import_path
    assert_redirected_to @import.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_import_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get new_import_path, params: {
      import: {
        institution_id: institutions(:southwest).id
      }
    }
    assert_response :ok
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get import_path(@import)
    assert_response :not_found
  end

  test "show() redirects to root page for logged-out users" do
    get import_path(@import)
    assert_redirected_to @import.institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get import_path(@import)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get import_path(@import)
    assert_response :ok
  end

  test "show() via XHR returns HTML" do
    log_in_as(users(:southwest_admin))
    get import_path(@import), xhr: true
    assert response.content_type.start_with?("text/html")
  end

  test "show() returns JSON" do
    log_in_as(users(:southwest_admin))
    get import_path(@import, format: :json)
    assert response.content_type.start_with?("application/json")
  end

  test "show() respects role limits" do
    log_in_as(users(:southwest_admin))
    get import_path(@import)
    assert_response :ok

    get import_path(@import, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    log_in_as(users(:southwest))
    patch import_path(@import)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    patch "/imports/99999"
    assert_redirected_to @import.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch import_path(@import)
    assert_response :forbidden
  end

  test "update() updates an import" do
    log_in_as(users(:southwest_admin))
    patch import_path(@import),
          xhr: true,
          params: {
            import: {
              filename: "cats.jpg",
              length:   12345
            }
          }
    @import.reload
    assert_equal "cats.jpg", @import.filename
    assert_equal 12345, @import.length
  end

  test "update() returns HTTP 204" do
    log_in_as(users(:southwest_admin))
    patch import_path(@import),
          xhr: true,
          params: {
            import: {
              institution_id: institutions(:southwest).id,
              name:           "cats"
            }
          }
    assert_response :no_content
  end

  test "update() returns HTTP 400 for illegal arguments" do
    skip # currently not possible to provide illegal arguments
    log_in_as(users(:southwest_admin))
    patch import_path(@import),
          xhr: true,
          params: {
            import: {
              length: "cats" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent imports" do
    log_in_as(users(:southwest_admin))
    patch "/imports/99999"
    assert_response :not_found
  end

end
