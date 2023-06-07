require 'test_helper'

class ElementNamespacesControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
    @namespace = element_namespaces(:southwest_dc)
  end

  teardown do
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post element_namespaces_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post element_namespaces_path
    assert_redirected_to @namespace.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    user = users(:southwest)
    log_in_as(user)
    post element_namespaces_path,
         xhr: true,
         params: {
           element_namespace: {
             institution_id: user.institution.id,
             prefix:         "new",
             uri:            "http://example.org/new/"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:southwest_admin)
    log_in_as(user)
    post element_namespaces_path,
         xhr: true,
         params: {
           element_namespace: {
             institution_id: user.institution.id,
             prefix:         "new",
             uri:            "http://example.org/new/"
           }
         }
    assert_response :ok
  end

  test "create() creates a correct namespace" do
    user = users(:southwest_admin)
    log_in_as(user)
    assert_difference "ElementNamespace.count" do
      post element_namespaces_path,
           xhr: true,
           params: {
             element_namespace: {
               institution_id: user.institution.id,
               prefix:         "new",
               uri:            "http://example.org/new/"
             }
           }
    end
    namespace = ElementNamespace.order(created_at: :desc).limit(1).first
    assert_equal user.institution, namespace.institution
    assert_equal "new", namespace.prefix
    assert_equal "http://example.org/new/", namespace.uri
  end

  test "create() returns HTTP 400 for illegal arguments" do
    user = users(:southwest_admin)
    log_in_as(user)
    post element_namespaces_path,
         xhr: true,
         params: {
           element_namespace: {
             institution_id: user.institution.id,
             prefix:         "", # invalid
             uri:            "http://example.org/new/"
           }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    @namespace = element_namespaces(:southwest_dc)
    delete element_namespace_path(@namespace)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    @namespace = element_namespaces(:southwest_dc)
    delete element_namespace_path(@namespace)
    assert_redirected_to @namespace.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete element_namespace_path(element_namespaces(:southwest_dc))
    assert_response :forbidden
  end

  test "destroy() destroys the namespace" do
    log_in_as(users(:southwest_admin))
    namespace = element_namespaces(:southwest_dc)
    assert_difference "ElementNamespace.count", -1 do
      delete element_namespace_path(namespace)
    end
  end

  test "destroy() redirects to element namespaces view for non-sysadmins" do
    log_in_as(users(:southwest_admin))
    namespace = element_namespaces(:southwest_dc)
    delete element_namespace_path(namespace)
    assert_redirected_to element_namespaces_path
  end

  test "destroy() redirects to the namespace's institution for sysadmins" do
    log_in_as(users(:southwest_sysadmin))
    namespace = element_namespaces(:southwest_dc)
    delete element_namespace_path(namespace)
    assert_redirected_to institution_path(namespace.institution)
  end

  test "destroy() returns HTTP 404 for a missing namespace" do
    log_in_as(users(:southwest_admin))
    delete "/element-namespaces/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get edit_element_namespace_path(@namespace)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    get edit_element_namespace_path(@namespace)
    assert_redirected_to @namespace.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get edit_element_namespace_path(@namespace)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get edit_element_namespace_path(@namespace)
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:southwest_admin))
    get edit_element_namespace_path(@namespace)
    assert_response :ok

    get edit_element_namespace_path(@namespace, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get element_namespaces_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get element_namespaces_path
    assert_redirected_to @namespace.institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get element_namespaces_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get element_namespaces_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get element_namespaces_path
    assert_response :ok

    get element_namespaces_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_element_namespace_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_element_namespace_path
    assert_redirected_to @namespace.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_element_namespace_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get new_element_namespace_path,
        params: {
          element_namespace: {
            institution_id: institutions(:uiuc).id
          }
        }
    assert_response :ok
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    log_in_as(users(:southwest))
    patch element_namespace_path(element_namespaces(:southwest_dc))
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    patch "/element-namespaces/99999"
    assert_redirected_to @namespace.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch element_namespace_path(element_namespaces(:southwest_dc))
    assert_response :forbidden
  end

  test "update() updates a namespace" do
    user = users(:southwest_admin)
    log_in_as(user)
    patch element_namespace_path(@namespace),
          xhr: true,
          params: {
            element_namespace: {
              institution_id: user.institution.id,
              prefix:         "new",
              uri:            "http://example.org/new/"
            }
          }
    @namespace.reload
    assert_equal "new", @namespace.prefix
    assert_equal "http://example.org/new/", @namespace.uri
  end

  test "update() returns HTTP 200" do
    user = users(:southwest_admin)
    log_in_as(user)
    patch element_namespace_path(@namespace),
          xhr: true,
          params: {
            element_namespace: {
              institution_id: user.institution.id,
              prefix:         "new",
              uri:            "http://example.org/new/"
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    user = users(:southwest_admin)
    log_in_as(user)
    patch element_namespace_path(@namespace),
          xhr: true,
          params: {
            element_namespace: {
              institution_id: user.institution.id,
              prefix:         "", # invalid
              uri:            "http://example.org/new/"
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent namespaces" do
    log_in_as(users(:southwest_admin))
    patch "/element-namespaces/99999"
    assert_response :not_found
  end

end
