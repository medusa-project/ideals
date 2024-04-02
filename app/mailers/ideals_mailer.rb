# frozen_string_literal: true

class IdealsMailer < ApplicationMailer

  NO_REPLY_ADDRESS = ::Configuration.instance.mail[:no_reply_address]

  default from: "#{::Configuration.instance.website[:global_service_name]} <#{NO_REPLY_ADDRESS}>"

  ##
  # @param exception [Exception]
  # @param detail [String]   Additional message text.
  # @param method [String]   Request HTTP method.
  # @param host [String]     Request host.
  # @param url_path [String] Request URL path.
  # @param query [String]    Request query string.
  # @param user [User]       Request user.
  # @return [String]
  #
  def self.error_body(exception,
                      detail:   nil,
                      method:   nil,
                      host:     nil,
                      url_path: nil,
                      query:    nil,
                      user:     nil)
    io = StringIO.new
    io << "Class:   #{exception.class}\n"
    io << "Message: #{exception.message}\n"
    io << "Detail:  #{detail}\n" if detail
    io << "Time:    #{Time.now.strftime("%Y-%m-%d %l:%M:%S.%L %p")}\n"
    io << "Method:  #{method}\n" if method
    io << "Host:    #{host}\n" if host
    io << "Path:    #{url_path}\n" if url_path
    io << "Query:   ?#{query}\n" if query
    io << "User:    #{user.email} (#{user.name})\n" if user
    io << "Stack Trace:\n"
    exception.backtrace.each do |line|
      io << line
      io << "\n"
    end
    io.string
  end

  ##
  # Notifies the given local-credentials user that their request to register
  # has been approved, and contains a link to the registration form.
  #
  # This is the counterpart of {invited} for self-invited users.
  #
  # @param credential [Credential]
  #
  def account_approved(credential)
    @credential  = credential
    @institution = @credential.user.institution
    mail(to:      @credential.email,
         subject: "Register your #{@institution.service_name} account")
  end

  ##
  # Notifies the given invitee that their request to register has been denied.
  #
  # @param invitee [Invitee]
  #
  def account_denied(invitee)
    @invitee     = invitee
    @institution = @invitee.institution
    mail(to:      @invitee.email,
         subject: "Your #{@institution.service_name} account request")
  end

  ##
  # Notifies the given invitee that their registration has been
  # received/approved, and contains a link to log in.
  #
  # @param credential [Credential]
  #
  def account_registered(credential)
    @credential  = credential
    @institution = @credential.user.institution
    mail(to:      @credential.email,
         subject: "Welcome to #{@institution.service_name}!")
  end

  ##
  # Notifies sysadmins that a user has requested to register and needs to be
  # approved to do so. Used in conjunction with {account_request_received}.
  #
  # @param invitee [Invitee]
  #
  def account_request_action_required(invitee)
    # The feedback email may not be set yet for new institutions that haven't
    # been set up properly. In that case it would be better to provide a
    # more helpful error than "SMTP To address not set."
    @institution = invitee.institution
    if !@institution
      raise "This invitee is not associated with an institution."
    elsif @institution.feedback_email.blank?
      raise "This institution's feedback email is not set."
    end
    @invitee     = invitee
    scheme       = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
    @invitee_url = "#{scheme}://#{@institution.fqdn}/invitees/#{invitee.id}"
    mail(to:      @institution.feedback_email,
         subject: "#{subject_prefix} Action required on a new "\
                  "#{@institution.service_name} user")
  end

  ##
  # Notifies the given invitee that their request to register has
  # been received, and will soon be acted upon, at which time they will receive
  # an email from {account_approved} or {account_denied}. Used in conjunction
  # with {account_request_action_required}.
  #
  # @param invitee [Invitee]
  #
  def account_request_received(invitee)
    @invitee     = invitee
    @institution = @invitee.institution
    mail(to:      @invitee.email,
         subject: "Your #{@institution.service_name} account request")
  end

  ##
  # Used for user feedback from a contact form.
  #
  # @param from_email [String] Email address entered into a contact form.
  # @param from_name [String]  Name entered into a contact form.
  # @param page_url [String]   URL on which the contact form appears.
  # @param comment [String]    Comment entered into a contact form.
  # @param to_email [String]   Email address to which the feedback is to be
  #                            routed.
  #
  def contact(from_email:, from_name:, page_url:, comment:, to_email:)
    @from_email = from_email.present? ? from_email : "Not Supplied"
    @from_name  = from_name.present? ? from_name: "Not Supplied"
    @page_url   = page_url
    @comment    = comment
    mail(from:    from_email.present? ? from_email : NO_REPLY_ADDRESS,
         to:      to_email,
         subject: "#{subject_prefix} User feedback received")
  end

  def error(error_text)
    @error_text = error_text
    mail(to:      ::Configuration.instance.admin[:tech_mail_list],
         subject: "#{subject_prefix} System Error")
  end

  ##
  # Notifies the given invitee that a staff member has invited them to
  # register.
  #
  # This is the counterpart of {account_approved} for users who have been
  # invited (and therefore pre-approved) by a sysadmin.
  #
  # @param credential [Credential]
  #
  def invited(credential)
    @credential  = credential
    @institution = @credential.user.institution
    mail(to:      @credential.email,
         subject: "Register for an account with #{@institution.service_name}")
  end

  ##
  # Sends an email to an item's submitter after it has been approved.
  #
  # @param item [Item]
  #
  def item_approved(item)
    @item_title      = item.effective_title
    @item_handle_url = item.handle.url
    mail(to:      [item.submitter.email],
         subject: "Your item has been approved")
  end

  ##
  # Sends an email to an item's submitter after it has been rejected.
  #
  # @param item [Item]
  #
  def item_rejected(item)
    @item_title       = item.effective_title
    @collection_title = item.primary_collection.title
    @service_name     = item.institution.service_name
    @feedback_email   = item.institution.feedback_email
    mail(to:      [item.submitter.email],
         subject: "Your item has been rejected")
  end

  ##
  # Sends an email to the administrators of a collection (but **not**
  # administrators of its owning unit/institution) when an item has been
  # submitted to it and it is requiring review of submissions.
  #
  # @param item [Item]
  #
  def item_requires_review(item)
    @institution      = item.institution
    @item_url         = item_url(item, host: @institution.scope_url)
    @review_url       = review_items_url(host: @institution.scope_url)
    collection        = item.effective_primary_collection
    recipient_emails  = Set.new
    recipient_emails += (collection&.administering_users || []).map(&:email)
    recipient_emails += (collection&.administering_groups || []).map{ |g| g.users.map(&:email) }.flatten
    if recipient_emails.any?
      mail(to:      recipient_emails.to_a,
           subject: "A new #{@institution.service_name} item requires review")
    end
  end

  ##
  # Sends an email to an item's submitter after it has been submitted.
  #
  # @param item [Item]
  #
  def item_submitted(item)
    @item_title           = item.effective_title
    @submissions_reviewed = item.primary_collection.submissions_reviewed
    @service_name         = item.institution.service_name
    mail(to:       [item.submitter.email],
         reply_to: [item.institution.feedback_email],
         subject:  "Your item has been submitted")
  end

  ##
  # @param credential [Credential]
  #
  def password_reset(credential)
    @credential  = credential
    @institution = @credential.user.institution
    mail(to:      @credential.email,
         subject: "Reset your #{@institution.service_name} password")
  end

  ##
  # Used to test email delivery. See also the `mail:test` rake task.
  #
  def test(recipient)
    mail(to:      recipient,
         subject: "#{subject_prefix} Hello from Illinois IR")
  end

  private

  def subject_prefix
    "[#{Rails.env.to_s.upcase}: Illinois IR]"
  end
end
