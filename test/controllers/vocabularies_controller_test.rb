require 'test_helper'

class VocabulariesControllerTest < ActionDispatch::IntegrationTest

  teardown do
    log_out
  end

  # create()

  test "create() redirects to login page for logged-out users" do
    post vocabularies_path
    assert_redirected_to login_path
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    post vocabularies_path,
         xhr: true,
         params: {
           vocabulary: {
             name: "New"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    user = users(:uiuc_admin)
    log_in_as(user)
    post vocabularies_path,
         xhr: true,
         params: {
           vocabulary: {
             name: "New"
           }
         }
    assert_response :ok
  end

  test "create() creates a correct vocabulary" do
    user = users(:uiuc_admin)
    log_in_as(user)
    post vocabularies_path,
         xhr: true,
         params: {
           vocabulary: {
             name: "New"
           }
         }
    vocab = Vocabulary.order(created_at: :desc).limit(1).first
    assert_equal user.institution, vocab.institution
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    post vocabularies_path,
         xhr: true,
         params: {
           vocabulary: {
             name: ""
           }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to login page for logged-out users" do
    delete vocabulary_path(vocabularies(:southwest_one))
    assert_redirected_to login_path
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    delete vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "destroy() destroys the vocabulary" do
    log_in_as(users(:local_sysadmin))
    vocab = vocabularies(:southwest_one)
    assert_difference "Vocabulary.count", -1 do
      delete vocabulary_path(vocab)
    end
  end

  test "destroy() returns HTTP 302 for an existing vocabulary" do
    log_in_as(users(:local_sysadmin))
    vocab = vocabularies(:southwest_one)
    delete vocabulary_path(vocab)
    assert_redirected_to vocabularies_path
  end

  test "destroy() returns HTTP 404 for a missing vocabulary" do
    log_in_as(users(:local_sysadmin))
    delete "/vocabularies/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to login page for logged-out users" do
    get edit_vocabulary_path(vocabularies(:southwest_one))
    assert_redirected_to login_path
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get edit_vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get edit_vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get edit_vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok

    get edit_vocabulary_path(vocabularies(:southwest_one),
                             role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() redirects to login page for logged-out users" do
    get vocabularies_path
    assert_redirected_to login_path
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get vocabularies_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get vocabularies_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get vocabularies_path
    assert_response :ok

    get vocabularies_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() redirects to login page for logged-out users" do
    get new_vocabulary_path
    assert_redirected_to login_path
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get new_vocabulary_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get new_vocabulary_path
    assert_response :ok
  end

  test "new() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get new_vocabulary_path
    assert_response :ok

    get new_vocabulary_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() redirects to login page for logged-out users" do
    get vocabulary_path(vocabularies(:southwest_one))
    assert_redirected_to login_path
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    get vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:local_sysadmin))
    get vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:local_sysadmin))
    get vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok

    get vocabulary_path(vocabularies(:southwest_one),
                        role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() redirects to login page for logged-out users" do
    patch vocabulary_path(vocabularies(:southwest_one))
    assert_redirected_to login_path
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:norights))
    patch vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "update() updates a vocabulary" do
    log_in_as(users(:local_sysadmin))
    vocab = vocabularies(:southwest_one)
    patch vocabulary_path(vocab),
          xhr: true,
          params: {
            vocabulary: {
              name: "New"
            }
          }
    vocab.reload
    assert_equal "New", vocab.name
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:local_sysadmin))
    vocab = vocabularies(:southwest_one)
    patch vocabulary_path(vocab),
          xhr: true,
          params: {
            vocabulary: {
              name: "Cats"
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:local_sysadmin))
    vocab = vocabularies(:southwest_one)
    patch vocabulary_path(vocab),
          xhr: true,
          params: {
            vocabulary: {
              name: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for a nonexistent vocabulary" do
    log_in_as(users(:local_sysadmin))
    patch "/vocabularies/99999"
    assert_response :not_found
  end

end
