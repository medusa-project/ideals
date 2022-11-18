require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @bulkfile = fixture_file_upload(file_fixture("escher_lego.png"), 'image/jpeg')
    @import   = imports(:saf_new)
    setup_s3
  end

  teardown do
    @import.delete_all_files
  end

  # create()

  test "create() returns HTTP 403 for logged-out users" do
    post imports_path, xhr: true
    assert_response :forbidden
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post imports_path, xhr: true
    assert_response :forbidden
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:uiuc_admin))
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
    user = users(:uiuc_admin)
    log_in_as(user)
    post imports_path,
         xhr: true,
         params: {
           import: {
             collection_id: collections(:uiuc_collection1).id
           }
         }
    assert_response :ok
  end

  test "create() creates a correct instance" do
    user = users(:uiuc_admin)
    log_in_as(user)
    assert_difference "Import.count" do
      post imports_path,
           xhr: true,
           params: {
             import: {
               collection_id: collections(:uiuc_collection1).id
             }
           }
    end
    import = Import.order(created_at: :desc).limit(1).first
    assert_equal user.institution, import.institution
    assert_equal user, import.user
  end

  # delete_all_files()

  test "delete_all_files() redirects to login page for logged-out users" do
    post import_delete_all_files_path(@import)
    assert_redirected_to login_path
  end

  test "delete_all_files() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    @import = imports(:saf_new)
    post import_delete_all_files_path(@import)
    assert_response :forbidden
  end

  test "delete_all_files() returns HTTP 204 for authorized users" do
    log_in_as(users(:uiuc_admin))
    @import = imports(:saf_new)
    post import_delete_all_files_path(@import)
    assert_response :no_content
  end

  test "delete_all_files() deletes all files associated with the import" do
    user = users(:uiuc_admin)
    log_in_as(user)

    @import = imports(:saf_new)
    File.open(file_fixture("escher_lego.png"), "r") do |file|
      @import.upload_file(relative_path: "item1/image.jpg", io: file)
    end
    assert_equal 1, @import.object_keys.length

    post import_delete_all_files_path(@import)
    assert_equal 0, @import.object_keys.length
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    import = imports(:saf_new)
    get edit_import_path(import)
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    import = imports(:saf_new)
    get edit_import_path(import)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    import = imports(:saf_new)
    get edit_import_path(import)
    assert_response :ok
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get imports_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get imports_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get imports_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:uiuc_admin))
    get imports_path
    assert_response :ok

    get imports_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() redirects to login page for logged-out users" do
    get new_import_path
    assert_redirected_to login_path
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get new_import_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get new_import_path
    assert_response :ok
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get import_path(@import)
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get import_path(@import)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:uiuc_admin))
    get import_path(@import)
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:uiuc_admin))
    get import_path(@import)
    assert_response :ok

    get import_path(@import, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch "/imports/bogus"
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch import_path(@import)
    assert_response :forbidden
  end

  test "update() updates an element" do
    log_in_as(users(:uiuc_admin))
    import        = imports(:saf_new)
    collection_id = collections(:uiuc_collection1).id
    patch "/imports/#{import.id}",
          xhr: true,
          params: {
            import: {
              collection_id: collection_id
            }
          }
    import.reload
    assert_equal collection_id, import.collection_id
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:uiuc_admin))
    import = imports(:saf_new)
    patch import_path(import),
          xhr: true,
          params: {
            import: {
              collection_id: collections(:uiuc_collection1).id
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 404 for nonexistent elements" do
    log_in_as(users(:uiuc_admin))
    patch "/elements/bogus"
    assert_response :not_found
  end

  # upload_file()

  test "upload_file() redirects to login page for logged-out users" do
    post import_upload_file_path(@import)
    assert_redirected_to login_path
  end

  test "upload_file() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    @import = imports(:saf_new)
    post import_upload_file_path(@import)
    assert_response :forbidden
  end

  test "upload_file() returns HTTP 204 for authorized users" do
    log_in_as(users(:uiuc_admin))
    @import = imports(:saf_new)
    post import_upload_file_path(@import),
         headers: { "X-Relative-Path": "/item1/image.jpg" },
         params:  { bulkfile: @bulkfile }

    assert_response :no_content
  end

  test "upload_file() returns HTTP 400 for a missing X-Relative-Path header" do
    log_in_as(users(:uiuc_admin))
    @import = imports(:saf_new)
    post import_upload_file_path(@import),
         xhr: true,
         params: {
           bulkfile: @bulkfile
         }
    assert_response :bad_request
  end

  test "upload_file() uploads a file to the application S3 bucket" do
    user = users(:uiuc_admin)
    log_in_as(user)

    assert_equal 0, @import.object_keys.length

    @import = imports(:saf_new)
    post import_upload_file_path(@import),
         headers: { "X-Relative-Path": "/item1/image.jpg" },
         params:  { bulkfile: @bulkfile }

    assert_equal 1, @import.object_keys.length
  end

end
