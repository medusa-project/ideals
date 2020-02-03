require 'test_helper'

class UnitsControllerTest < ActionDispatch::IntegrationTest

  setup do
    log_in_as(user_identity(:admin))
  end

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for unauthorized users" do
    log_out
    post units_path, {}
    assert_redirected_to login_path
  end

  test "create() returns HTTP 200 for authorized users" do
    post units_path, {
        xhr: true,
        params: {
            unit: {
                title: "New Unit"
            }
        }
    }
    assert_response :ok
  end

  test "create() creates a unit" do
    post units_path, {
        xhr: true,
        params: {
            unit: {
                title: "New Unit"
            }
        }
    }
    assert_not_nil Unit.find_by_title("New Unit")
  end

  test "create() returns HTTP 400 for illegal arguments" do
    post units_path, {
        xhr: true,
        params: {
            unit: {
                title: ""
            }
        }
    }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login path for unauthorized users" do
    log_out
    delete "/units/#{units(:unit1).id}"
    assert_redirected_to login_path
  end

  test "destroy() destroys the unit" do
    # choose a unit with no dependent collections or units to make setup easier
    unit = units(:unit1_unit2_unit1)
    delete "/units/#{unit.id}"
    assert_raises ActiveRecord::RecordNotFound do
      Unit.find(unit.id)
    end
  end

  test "destroy() returns HTTP 302 for an existing unit" do
    unit = units(:unit1)
    delete "/units/#{unit.id}"
    assert_redirected_to units_path
  end

  test "destroy() returns HTTP 404 for a missing unit" do
    delete "/units/bogus"
    assert_response :not_found
  end

  # update()

  test "update() redirects to login path for unauthorized users" do
    log_out
    unit = units(:unit1)
    patch "/units/#{unit.id}", {}
    assert_redirected_to login_path
  end

  test "update() updates a unit" do
    unit = units(:unit1)
    patch "/units/#{unit.id}", {
        xhr: true,
        params: {
            unit: {
                title: "cats"
            }
        }
    }
    unit.reload
    assert_equal "cats", unit.title
  end

  test "update() returns HTTP 200" do
    unit = units(:unit1)
    patch "/units/#{unit.id}", {
        xhr: true,
        params: {
            unit: {
                title: "cats"
            }
        }
    }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    unit = units(:unit1)
    patch "/units/#{unit.id}", {
        xhr: true,
        params: {
            unit: {
                title: "" # invalid
            }
        }
    }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent units" do
    patch "/units/bogus", {}
    assert_response :not_found
  end

end
