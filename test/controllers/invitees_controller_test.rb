require 'test_helper'

class InviteesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @invitee = invitees(:example_pending)
    host! @invitee.institution.fqdn
  end

  # approve()

  test "approve() redirects to root page for logged-out users" do
    patch invitee_approve_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "approve() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
    patch invitee_approve_path(@invitee)
    assert_response :forbidden
  end

  test "approve() approves an invitee and sends an email" do
    log_in_as(users(:example_sysadmin))
    assert !@invitee.approved?

    assert_emails 1 do
      patch invitee_approve_path(@invitee)
      @invitee.reload
      assert @invitee.approved?
    end
  end

  test "approve() sets the flash and redirects upon success" do
    log_in_as(users(:example_sysadmin))
    patch invitee_approve_path(@invitee)
    assert_redirected_to invitees_path
    assert flash['success'].start_with?("Invitee #{@invitee.email} has been approved")
  end

  # create()

  test "create() returns HTTP 400 for illegal arguments" do
    log_in_as(users(:example_sysadmin))

    post invitees_path,
         xhr: true,
         params: {
             invitee: {
                 email: "",
                 note: "This is a new invitee"
             }
         }
    assert_response :bad_request
  end

  test "create() creates an approved instance and sends an email if all
  arguments are valid" do
    log_in_as(users(:example_sysadmin))

    email = "new@example.edu"
    assert_nil Invitee.find_by_email(email)

    assert_emails 1 do
      post invitees_path,
           xhr: true,
           params: {
               invitee: {
                   email: email,
                   note: "This is a new invitee"
               }
           }
      invitee = Invitee.find_by_email(email)
      assert_equal Invitee::ApprovalState::APPROVED, invitee.approval_state
    end
  end

  test "create() sets the flash if all arguments are valid" do
    log_in_as(users(:example_sysadmin))

    post invitees_path,
         xhr: true,
         params: {
             invitee: {
                 email: "new@example.edu",
                 note: "This is a new invitee"
             }
         }
    assert flash['success'].include?("An invitation has been sent")
  end

  test "create() returns HTTP 200 if all arguments are valid" do
    log_in_as(users(:example_sysadmin))

    post invitees_path,
         xhr: true,
         params: {
             invitee: {
                 email: "new@example.edu",
                 note: "This is a new invitee"
             }
         }
    assert_response :ok
  end

  # create_unsolicited()

  test "create_unsolicited() redirects back for illegal arguments" do
    post create_unsolicited_invitees_path,
         params: {
           honey_email: "",
           correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
           answer: "5",
           invitee: {
             email: "", # invalid
             note: "This is a new invitee"
           }
         }
    assert_redirected_to new_invitee_path
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
             email: email,
             note: "This is a new invitee"
           }
         }
    assert flash['error'].start_with?("Incorrect math question response")
    assert_redirected_to new_invitee_path
  end

  test "create_unsolicited() sets the flash and redirects if all arguments are
  valid" do
    post create_unsolicited_invitees_path,
         params: {
           honey_email: "",
           correct_answer_hash: Digest::MD5.hexdigest("5" + ApplicationHelper::CAPTCHA_SALT),
           answer: "5",
           invitee: {
             email: "new@example.edu",
             note: "This is a new invitee"
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
               email: email,
               note: "This is a new invitee"
             }
           }
    end
    invitee = Invitee.find_by_email(email)
    assert_equal Invitee::ApprovalState::PENDING, invitee.approval_state
  end

  # destroy()

  test "destroy() redirects to root page for logged-out users" do
    delete invitee_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "destroy() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
    delete invitee_path(@invitee)
    assert_response :forbidden
  end

  test "destroy() destroys the invitee" do
    log_in_as(users(:example_sysadmin))
    assert_difference "Invitee.count", -1 do
      delete invitee_path(@invitee)
    end
  end

  test "destroy() returns HTTP 302 for an existing invitee" do
    log_in_as(users(:example_sysadmin))
    delete invitee_path(@invitee)
    assert_redirected_to invitees_path
  end

  test "destroy() returns HTTP 404 for a missing invitee" do
    log_in_as(users(:example_sysadmin))
    delete "/invitees/bogus"
    assert_response :not_found
  end

  # index()

  test "index() redirects to root page for logged-out users" do
    get invitees_path
    assert_redirected_to @invitee.institution.scope_url
  end

  test "index() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
    get invitees_path
    assert_response :forbidden
  end

  test "index() returns HTTP 200 for authorized users" do
    log_in_as(users(:example_sysadmin))
    get invitees_path
    assert_response :ok
  end

  test "index() respects role limits" do
    log_in_as(users(:example_sysadmin))
    get invitees_path
    assert_response :ok

    get invitees_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # index_all()

  test "index_all() redirects to root page for logged-out users" do
    get all_invitees_path
    assert_redirected_to @invitee.institution.scope_url
  end

  test "index_all() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
    get all_invitees_path
    assert_response :forbidden
  end

  test "index_all() returns HTTP 200 for authorized users" do
    log_in_as(users(:example_sysadmin))
    get all_invitees_path
    assert_response :ok
  end

  test "index_all() respects role limits" do
    log_in_as(users(:example_sysadmin))
    get all_invitees_path
    assert_response :ok

    get all_invitees_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

  # new()

  test "new() redirects to root path for logged-in users" do
    log_in_as(users(:example))
    get new_invitee_path
    assert_redirected_to root_path
  end

  test "new() returns HTTP 200 for logged-out users" do
    get new_invitee_path
    assert_response :ok
  end

  # reject()

  test "reject() redirects to root page for logged-out users" do
    patch invitee_reject_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "reject() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
    patch invitee_reject_path(@invitee)
    assert_response :forbidden
  end

  test "reject() rejects an invitee and sends an email" do
    log_in_as(users(:example_sysadmin))
    assert !@invitee.rejected?

    assert_emails 1 do
      patch invitee_reject_path(@invitee)
      @invitee.reload
      assert @invitee.rejected?
    end
  end

  test "reject() sets the flash and redirects upon success" do
    log_in_as(users(:example_sysadmin))
    patch invitee_reject_path(@invitee)
    assert_redirected_to invitees_path
    assert flash['success'].start_with?("Invitee #{@invitee.email} has been rejected")
  end

  # resend_email()

  test "resend_email() redirects to root page for logged-out users" do
    patch invitee_resend_email_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "resend_email() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
    patch invitee_resend_email_path(@invitee)
    assert_response :forbidden
  end

  test "resend_email() redirects to the invitees path upon success" do
    log_in_as(users(:example_sysadmin))
    patch invitee_resend_email_path(@invitee)
    assert_redirected_to invitees_path
  end

  test "resend_email() emails an invitee" do
    log_in_as(users(:example_sysadmin))
    @invitee = invitees(:example_approved)
    assert_emails 1 do
      patch invitee_resend_email_path(@invitee)
    end
  end

  # show()

  test "show() redirects to root page for logged-out users" do
    get invitee_path(@invitee)
    assert_redirected_to @invitee.institution.scope_url
  end

  test "show() returns HTTP 403 for unauthorized users" do
    log_in_as(users(:example))
    get invitee_path(@invitee)
    assert_response :forbidden
  end

  test "show() returns HTTP 200 for authorized users" do
    log_in_as(users(:example_sysadmin))
    get invitee_path(@invitee)
    assert_response :ok
  end

  test "show() respects role limits" do
    log_in_as(users(:example_sysadmin))
    get invitee_path(@invitee)
    assert_response :ok

    get invitees_path(role: Role::LOGGED_OUT)
    assert_response :forbidden
  end

end
