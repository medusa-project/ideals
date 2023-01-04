require 'test_helper'

class VocabularyTermsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @vocab = vocabularies(:southwest_one)
    host! @vocab.institution.fqdn
  end

  teardown do
    log_out
  end

  # create()

  test "create() redirects to root page for logged-out users" do
    post vocabulary_vocabulary_terms_path(@vocab)
    assert_redirected_to @vocab.institution.scope_url
  end

  test "create() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    post vocabulary_vocabulary_terms_path(@vocab),
         xhr: true,
         params: {
           vocabulary_term: {
             vocabulary_id:   @vocab.id,
             stored_value:    "test",
             displayed_value: "Test"
           }
         }
    assert_response :forbidden
  end

  test "create() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    post vocabulary_vocabulary_terms_path(@vocab),
         xhr: true,
         params: {
           vocabulary_term: {
             vocabulary_id:   @vocab.id,
             stored_value:    "test",
             displayed_value: "Test"
           }
         }
    assert_response :ok
  end

  test "create() creates a term" do
    log_in_as(users(:southwest_admin))
    assert_difference "VocabularyTerm.count" do
      post vocabulary_vocabulary_terms_path(@vocab),
           xhr: true,
           params: {
             vocabulary_term: {
               vocabulary_id:   @vocab.id,
               stored_value:    "test",
               displayed_value: "Test"
             }
           }
    end
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    post vocabulary_vocabulary_terms_path(@vocab),
         xhr: true,
         params: {
           vocabulary_term: {
             vocabulary_id:   @vocab.id,
             stored_value:    "", # invalid
             displayed_value: "Test"
           }
         }
    assert_response :bad_request
  end

  # destroy()

  test "destroy() redirects to root page for logged-out users" do
    delete vocabulary_vocabulary_term_path(@vocab,
                                           vocabulary_terms(:southwest_one_one))
    assert_redirected_to @vocab.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete vocabulary_vocabulary_term_path(@vocab,
                                           vocabulary_terms(:southwest_one_one))
    assert_response :forbidden
  end

  test "destroy() destroys the term" do
    log_in_as(users(:southwest_admin))
    term = vocabulary_terms(:southwest_one_one)
    assert_difference "VocabularyTerm.count", -1 do
      delete vocabulary_vocabulary_term_path(term.vocabulary, term)
    end
  end

  test "destroy() returns HTTP 302 for an existing term" do
    log_in_as(users(:southwest_admin))
    term = vocabulary_terms(:southwest_one_one)
    delete vocabulary_vocabulary_term_path(term.vocabulary, term)
    assert_redirected_to term.vocabulary
  end

  test "destroy() returns HTTP 404 for a missing term" do
    log_in_as(users(:southwest_admin))
    delete vocabulary_path(@vocab) + "/terms/9999"
    assert_response :not_found
  end

  # edit()

  test "edit() redirects to root page for logged-out users" do
    term = vocabulary_terms(:southwest_one_one)
    get edit_vocabulary_vocabulary_term_path(@vocab, term)
    assert_redirected_to @vocab.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    term = vocabulary_terms(:southwest_one_one)
    get edit_vocabulary_vocabulary_term_path(@vocab, term)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    term = vocabulary_terms(:southwest_one_one)
    get edit_vocabulary_vocabulary_term_path(@vocab, term)
    assert_response :ok
  end

  # new()

  test "new() redirects to root page for logged-out users" do
    get new_vocabulary_vocabulary_term_path(@vocab)
    assert_redirected_to @vocab.institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_vocabulary_vocabulary_term_path(@vocab)
    assert_response :forbidden
  end

  test "new() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_admin))
    get new_vocabulary_vocabulary_term_path(@vocab)
    assert_response :ok
  end

  test "new() respects role limits" do
    log_in_as(users(:southwest_admin))
    get new_vocabulary_vocabulary_term_path(@vocab)
    assert_response :ok

    get new_vocabulary_vocabulary_term_path(@vocab, role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # update()

  test "update() redirects to root page for logged-out users" do
    term = vocabulary_terms(:southwest_one_one)
    patch vocabulary_vocabulary_term_path(@vocab, term)
    assert_redirected_to @vocab.institution.scope_url
  end

  test "update() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    term = vocabulary_terms(:southwest_one_one)
    patch vocabulary_vocabulary_term_path(@vocab, term)
    assert_response :forbidden
  end

  test "update() updates a term" do
    log_in_as(users(:southwest_admin))
    term = vocabulary_terms(:southwest_one_one)
    patch vocabulary_vocabulary_term_path(@vocab, term),
          xhr: true,
          params: {
            vocabulary_term: {
              vocabulary_id:   @vocab.id,
              stored_value:    "test",
              displayed_value: "Test"
            }
          }
    term.reload
    assert_equal "Test", term.displayed_value
  end

  test "update() returns HTTP 200" do
    log_in_as(users(:southwest_admin))
    term = vocabulary_terms(:southwest_one_one)
    patch vocabulary_vocabulary_term_path(@vocab, term),
          xhr: true,
          params: {
            vocabulary_term: {
              vocabulary_id:   @vocab.id,
              stored_value:    "new",
              displayed_value: "New"
            }
          }
    assert_response :ok
  end

  test "update() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_admin))
    term = vocabulary_terms(:southwest_one_one)
    patch vocabulary_vocabulary_term_path(@vocab, term),
          xhr: true,
          params: {
            vocabulary_term: {
              vocabulary_id:   @vocab.id,
              stored_value:    "new",
              displayed_value: "" # invalid
            }
          }
    assert_response :bad_request
  end

  test "update() returns HTTP 404 for nonexistent terms" do
    log_in_as(users(:southwest_admin))
    patch vocabulary_path(@vocab) + "/terms/9999"
    assert_response :not_found
  end

end
