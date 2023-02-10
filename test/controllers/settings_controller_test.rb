require 'test_helper'

class SettingsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southwest)
    host! @institution.fqdn
  end

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get settings_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get settings_path
    assert_redirected_to @institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get settings_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get settings_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get settings_path
    assert_response :ok

    get settings_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch settings_path
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    patch settings_path
    assert_redirected_to @institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch settings_path
    assert_response :forbidden
  end

  test "update() updates settings for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    patch settings_path, params: {
      settings: {
        cats: "yes"
      }
    }
    assert_equal "yes", Setting.find_by_key("cats").value
  end

  test "update() redirects to the settings page for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    patch settings_path, params: {
      settings: {
        cats: "yes"
      }
    }
    assert_redirected_to settings_path
  end

  test "update() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    patch settings_path, params: {
      settings: {
        cats: "yes"
      }
    }
    assert_redirected_to settings_path

    patch settings_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
