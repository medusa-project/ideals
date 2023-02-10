require 'test_helper'

class VocabulariesControllerTest < ActionDispatch::IntegrationTest

  setup do
    host! institutions(:southwest).fqdn
  end

  teardown do
    log_out
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post vocabularies_path
    assert_response :not_found
  end

  test "create() redirects to root page for logged-out users" do
    post vocabularies_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
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
    user = users(:southwest_admin)
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
    user = users(:southwest_admin)
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
    log_in_as(users(:southwest_admin))
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

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    vocab = vocabularies(:southwest_one)
    delete vocabulary_path(vocab)
    assert_response :not_found
  end

  test "destroy() redirects to root page for logged-out users" do
    vocab = vocabularies(:southwest_one)
    delete vocabulary_path(vocab)
    assert_redirected_to vocab.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "destroy() destroys the vocabulary" do
    log_in_as(users(:southwest_admin))
    vocab = vocabularies(:southwest_one)
    assert_difference "Vocabulary.count", -1 do
      delete vocabulary_path(vocab)
    end
  end

  test "destroy() returns HTTP 302 for an existing vocabulary" do
    log_in_as(users(:southwest_admin))
    vocab = vocabularies(:southwest_one)
    delete vocabulary_path(vocab)
    assert_redirected_to vocabularies_path
  end

  test "destroy() returns HTTP 404 for a missing vocabulary" do
    log_in_as(users(:southwest_admin))
    delete "/vocabularies/99999"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    vocab = vocabularies(:southwest_one)
    get edit_vocabulary_path(vocab)
    assert_response :not_found
  end

  test "edit() redirects to root page for logged-out users" do
    vocab = vocabularies(:southwest_one)
    get edit_vocabulary_path(vocab)
    assert_redirected_to vocab.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get edit_vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get edit_vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok
  end

  test "edit() respects role limits" do
    log_in_as(users(:southwest_admin))
    get edit_vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok

    get edit_vocabulary_path(vocabularies(:southwest_one),
                             role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get vocabularies_path
    assert_response :not_found
  end

  test "index() redirects to root page for logged-out users" do
    get vocabularies_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get vocabularies_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get vocabularies_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_admin))
    get vocabularies_path
    assert_response :ok

    get vocabularies_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_vocabulary_path
    assert_response :not_found
  end

  test "new() redirects to root page for logged-out users" do
    get new_vocabulary_path
    assert_redirected_to institutions(:southwest).scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_vocabulary_path
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get new_vocabulary_path
    assert_response :ok
  end

  test "new() respects role limits" do
    log_in_as(users(:southwest_admin))
    get new_vocabulary_path
    assert_response :ok

    get new_vocabulary_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    vocab = vocabularies(:southwest_one)
    get vocabulary_path(vocab)
    assert_response :not_found
  end

  test "show() redirects to root page for logged-out users" do
    vocab = vocabularies(:southwest_one)
    get vocabulary_path(vocab)
    assert_redirected_to vocab.institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:southwest_admin))
    get vocabulary_path(vocabularies(:southwest_one))
    assert_response :ok

    get vocabulary_path(vocabularies(:southwest_one),
                        role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    vocab = vocabularies(:southwest_one)
    patch vocabulary_path(vocab)
    assert_response :not_found
  end

  test "update() redirects to root page for logged-out users" do
    vocab = vocabularies(:southwest_one)
    patch vocabulary_path(vocab)
    assert_redirected_to vocab.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch vocabulary_path(vocabularies(:southwest_one))
    assert_response :forbidden
  end

  test "update() updates a vocabulary" do
    log_in_as(users(:southwest_admin))
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
    log_in_as(users(:southwest_admin))
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
    log_in_as(users(:southwest_admin))
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
    log_in_as(users(:southwest_admin))
    patch "/vocabularies/99999"
    assert_response :not_found
  end

end
