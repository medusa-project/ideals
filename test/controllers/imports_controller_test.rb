require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    @bulkfile = fixture_file_upload(file_fixture("escher_lego.png"), 'image/jpeg')
    @import   = imports(:southwest_saf_new)
    setup_s3
  end

  teardown do
    @import.delete_all_files
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

  # delete_all_files()

  test "delete_all_files() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post import_delete_all_files_path(@import)
    assert_response :not_found
  end

  test "delete_all_files() redirects to root page for logged-out users" do
    post import_delete_all_files_path(@import)
    assert_redirected_to @import.institution.scope_url
  end

  test "delete_all_files() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    @import = imports(:uiuc_saf_new)
    post import_delete_all_files_path(@import)
    assert_response :forbidden
  end

  test "delete_all_files() returns HTTP 204 for authorized users" do
    log_in_as(users(:southwest_admin))
    post import_delete_all_files_path(@import)
    assert_response :no_content
  end

  test "delete_all_files() deletes all files associated with the import" do
    user = users(:southwest_admin)
    log_in_as(user)
    @import.save_file(file:     File.new(file_fixture("escher_lego.png")),
                      filename: "image.jpg")

    assert File.exist?(@import.file)

    post import_delete_all_files_path(@import)
    assert !File.exist?(@import.file)
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

  test "show() respects role limits" do
    log_in_as(users(:southwest_admin))
    get import_path(@import)
    assert_response :ok

    get import_path(@import, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # upload_file()

  test "upload_file() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post import_upload_file_path(@import)
    assert_response :not_found
  end

  test "upload_file() redirects to root page for logged-out users" do
    post import_upload_file_path(@import)
    assert_redirected_to @import.institution.scope_url
  end

  test "upload_file() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    @import = imports(:uiuc_saf_new)
    post import_upload_file_path(@import)
    assert_response :forbidden
  end

  test "upload_file() returns HTTP 204 for authorized users" do
    log_in_as(users(:southwest_admin))
    post import_upload_file_path(@import), params: { file: @bulkfile }, xhr: true

    assert_response :no_content
  end

  test "upload_file() uploads a file" do
    user = users(:southwest_admin)
    log_in_as(user)

    assert_nil @import.file

    post import_upload_file_path(@import), params:  { file: @bulkfile }

    @import.reload
    assert File.exist?(@import.file)
  end

end
