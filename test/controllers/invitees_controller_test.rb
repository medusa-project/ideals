require 'test_helper'

class InviteesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @invitee     = invitees(:southwest_pending)
    @institution = @invitee.institution
    host! @institution.fqdn
  end

  # approve()

  test "approve() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch invitee_approve_path(@invitee)
    assert_response :not_found
  end

  test "approve() redirects to the scoped root page for logged-out users" do
    patch invitee_approve_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "approve() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch invitee_approve_path(@invitee)
    assert_response :forbidden
  end

  test "approve() approves an invitee and sends an email" do
    log_in_as(users(:southwest_sysadmin))
    assert !@invitee.approved?

    assert_emails 1 do
      patch invitee_approve_path(@invitee)
      @invitee.reload
      assert @invitee.approved?
    end
  end

  test "approve() redirects upon success" do
    log_in_as(users(:southwest_sysadmin))
    patch invitee_approve_path(@invitee)
    assert_redirected_to invitees_path
  end

  # create()

  test "create() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post invitees_path, xhr: true
    assert_response :not_found
  end

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:southwest_sysadmin))

    post invitees_path,
         xhr: true,
         params: {
             invitee: {
                 email:   "",
                 purpose: "This is a new invitee"
             }
         }
    assert_response :bad_request
  end

  test "create() returns HTTP 400 for an existing user" do
    log_in_as(users(:southwest_sysadmin))

    post invitees_path,
         xhr: true,
         params: {
           invitee: {
             email:   users(:southwest).email,
             purpose: "This shouldn't work"
           }
         }
    assert_response :bad_request
  end

  test "create() creates an approved instance and sends an email if all
  arguments are valid" do
    log_in_as(users(:southwest_sysadmin))

    email = "new@example.edu"
    assert_nil Invitee.find_by_email(email)

    assert_emails 1 do
      post invitees_path,
           xhr: true,
           params: {
               invitee: {
                   email:   email,
                   purpose: "This is a new invitee"
               }
           }
      invitee = Invitee.find_by_email(email)
      assert_equal Invitee::ApprovalState::APPROVED, invitee.approval_state
    end
  end

  test "create() returns HTTP 200 if all arguments are valid" do
    log_in_as(users(:southwest_sysadmin))

    post invitees_path,
         xhr: true,
         params: {
             invitee: {
                 email:   "new@example.edu",
                 purpose: "This is a new invitee"
             }
         }
    assert_response :ok
  end

  # create_unsolicited()

  test "create_unsolicited() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    post create_unsolicited_invitees_path
    assert_response :not_found
  end

  test "create_unsolicited() returns HTTP 403 when the institution does not
  allow user registration" do
    @institution.update!(allow_user_registration: false)
    post create_unsolicited_invitees_path, params: {
      honey_email: "",
      correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
      answer: "5",
      invitee: {
        email:   "new@example.edu",
        purpose: "This is a new invitee"
      }
    }
    assert_response :forbidden
  end

  test "create_unsolicited() redirects back for illegal arguments" do
    post create_unsolicited_invitees_path,
         params: {
           honey_email: "",
           correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
           answer: "5",
           invitee: {
             email:   "", # invalid
             purpose: "This is a new invitee"
           }
         }
    assert_redirected_to register_path
  end

  test "create_unsolicited() redirects back for an existing user" do
    post create_unsolicited_invitees_path,
         params: {
           honey_email: "",
           correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
           answer: "5",
           invitee: {
             email:   users(:southwest).email,
             purpose: "This is a new invitee"
           }
         }
    assert_redirected_to register_path
  end

  test "create_unsolicited() sets the flash and redirects back upon an
  incorrect CAPTCHA response" do
    email = "new@example.edu"
    assert_nil Invitee.find_by_email(email)

    post create_unsolicited_invitees_path,
         params: {
           honey_email: "",
           correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
           answer: "7", # WRONG!
           invitee: {
             email:   email,
             purpose: "This is a new invitee"
           }
         }
    assert flash['error'].start_with?("Incorrect math question response")
    assert_redirected_to register_path
  end

  test "create_unsolicited() sets the flash and redirects if all arguments are
  valid" do
    post create_unsolicited_invitees_path,
         params: {
           honey_email: "",
           correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
           answer: "5",
           invitee: {
             email:   "new@example.edu",
             purpose: "This is a new invitee"
           }
         }
    assert flash['success'].start_with?("Thanks for requesting")
    assert_redirected_to root_url.chomp("/")
  end

  test "create_unsolicited() creates a pending instance and sends two emails if
  all arguments are valid" do
    email = "new@example.edu"
    assert_nil Invitee.find_by_email(email)

    assert_emails 2 do
      post create_unsolicited_invitees_path,
           params: {
             honey_email: "",
             correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
             answer: "5",
             invitee: {
               email:   email,
               purpose: "This is a new invitee"
             }
           }
    end
    invitee = Invitee.find_by_email(email)
    assert_equal Invitee::ApprovalState::PENDING, invitee.approval_state
  end

  # destroy()

  test "destroy() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete invitee_path(@invitee)
    assert_response :not_found
  end

  test "destroy() redirects to the scoped root page for logged-out users" do
    delete invitee_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    delete invitee_path(@invitee)
    assert_response :forbidden
  end

  test "destroy() destroys the invitee" do
    log_in_as(users(:southwest_sysadmin))
    assert_difference "Invitee.count", -1 do
      delete invitee_path(@invitee)
    end
  end

  test "destroy() returns HTTP 302 for an existing invitee" do
    log_in_as(users(:southwest_sysadmin))
    delete invitee_path(@invitee)
    assert_redirected_to invitees_path
  end

  test "destroy() returns HTTP 404 for a missing invitee" do
    log_in_as(users(:southwest_sysadmin))
    delete "/invitees/bogus"
    assert_response :not_found
  end

  # edit()

  test "edit() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get edit_invitee_path(@invitee)
    assert_response :not_found
  end

  test "edit() redirects to the scoped root page for logged-out users" do
    get edit_invitee_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "edit() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get edit_invitee_path(@invitee)
    assert_response :forbidden
  end

  test "edit() returns HTTP 200 upon success" do
    log_in_as(users(:southwest_sysadmin))
    get edit_invitee_path(@invitee)
    assert_response :ok
  end

  # index()

  test "index() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    delete invitees_path
    assert_response :not_found
  end

  test "index() redirects to the scoped root page for logged-out users" do
    get invitees_path
    assert_redirected_to @invitee.institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get invitees_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get invitees_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get invitees_path
    assert_response :ok

    get invitees_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index_all()

  test "index_all() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get all_invitees_path
    assert_response :not_found
  end

  test "index_all() redirects to the scoped root page for logged-out users" do
    get all_invitees_path
    assert_redirected_to @invitee.institution.scope_url
  end

  test "index_all() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get all_invitees_path
    assert_response :forbidden
  end

  test "index_all() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get all_invitees_path
    assert_response :ok
  end

  test "index_all() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get all_invitees_path
    assert_response :ok

    get all_invitees_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get new_invitee_path
    assert_response :not_found
  end

  test "new() redirects to root path for logged-out users" do
    get new_invitee_path
    assert_redirected_to @institution.scope_url
  end

  test "new() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get new_invitee_path, params: {
      invitee: {
        institution_id: 0
      }
    }
    assert_response :forbidden
  end

  test "new() returns HTTP 400 for a missing institution_id argument" do
    log_in_as(users(:southwest_admin))
    get new_invitee_path
    assert_response :bad_request
  end

  test "new() returns HTTP 200 for institution administrators" do
    user = users(:southwest_admin)
    log_in_as(user)
    get new_invitee_path, params: {
      invitee: {
        institution_id: user.institution.id
      }
    }
    assert_response :ok
  end

  # register()

  test "register() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get register_path
    assert_response :not_found
  end

  test "register() redirects to root path for logged-in users" do
    log_in_as(users(:southwest))
    get register_path
    assert_redirected_to root_path
  end

  test "register() returns HTTP 403 when the institution does not allow
  user registration" do
    @institution.update!(allow_user_registration: false)
    get register_path
    assert_response :forbidden
  end

  test "register() returns HTTP 200 for logged-out users when the institution
  allows user registration" do
    get register_path
    assert_response :ok
  end

  # reject()

  test "reject() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch invitee_reject_path(@invitee)
    assert_response :not_found
  end

  test "reject() redirects to the scoped root page for logged-out users" do
    patch invitee_reject_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "reject() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch invitee_reject_path(@invitee)
    assert_response :forbidden
  end

  test "reject() rejects an invitee and sends an email" do
    log_in_as(users(:southwest_sysadmin))
    assert !@invitee.rejected?

    assert_emails 1 do
      patch invitee_reject_path(@invitee)
      @invitee.reload
      assert @invitee.rejected?
    end
  end

  test "reject() redirects upon success" do
    log_in_as(users(:southwest_sysadmin))
    patch invitee_reject_path(@invitee)
    assert_redirected_to invitees_path
  end

  # resend_email()

  test "resend_email() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    patch invitee_resend_email_path(@invitee)
    assert_response :not_found
  end

  test "resend_email() redirects to the scoped root page for logged-out users" do
    patch invitee_resend_email_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "resend_email() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    patch invitee_resend_email_path(@invitee)
    assert_response :forbidden
  end

  test "resend_email() redirects to the invitees path upon success" do
    log_in_as(users(:southwest_sysadmin))
    patch invitee_resend_email_path(@invitee)
    assert_redirected_to invitees_path
  end

  test "resend_email() emails an invitee" do
    log_in_as(users(:southwest_sysadmin))
    @invitee = invitees(:southwest_approved)
    assert_emails 1 do
      patch invitee_resend_email_path(@invitee)
    end
  end

  # show()

  test "show() returns HTTP 404 for unscoped requests" do
    host! ::Configuration.instance.main_host
    get invitee_path(@invitee)
    assert_response :not_found
  end

  test "show() redirects to the scoped root page for logged-out users" do
    get invitee_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:southwest))
    get invitee_path(@invitee)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:southwest_sysadmin))
    get invitee_path(@invitee)
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:southwest_sysadmin))
    get invitee_path(@invitee)
    assert_response :ok

    get invitees_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
