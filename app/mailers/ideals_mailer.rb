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
  # Notifies the given local-identity user that their request to register has
  # been approved, and contains a link to the registration form.
  #
  # This is the counterpart of {invited} for self-invited users.
  #
  # @param identity [LocalIdentity]
  #
  def account_approved(identity)
    @identity    = identity
    @institution = @identity.invitee.institution
    mail(to:      @identity.email,
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
  # @param identity [Identity]
  #
  def account_registered(identity)
    @identity    = identity
    @institution = @identity.invitee.institution
    mail(to:      @identity.email,
         subject: "Welcome to #{@institution.service_name}!")
  end

  ##
  # Notifies sysadmins that a user has requested to register and needs to be
  # approved to do so. Used in conjunction with {account_request_received}.
  #
  # @param invitee [Invitee]
  #
  def account_request_action_required(invitee)
    @institution = invitee.institution
    @invitee     = invitee
    @invitee_url = "https://#{@institution.fqdn}/invitees/#{invitee.id}"
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
  # @param identity [LocalIdentity]
  #
  def invited(identity)
    @identity    = identity
    @institution = @identity.invitee.institution
    mail(to:      @identity.email,
         subject: "Register for an account with #{@institution.service_name}")
  end

  ##
  # @param item [Item]
  #
  def item_submitted(item)
    @institution = item.institution
    @item_url    = item_url(item, host: @institution.scope_url)
    collection   = item.effective_primary_collection
    if collection
      recipients   = Set.new
      admin_users  = collection.effective_administrators || []
      admin_groups = collection.administering_groups || []
      if admin_users.any?
        recipients  += admin_users.map(&:email)
      end
      if admin_groups.any?
        recipients  += admin_groups.map{ |g| g.users.map(&:email) }.flatten
      end
      if recipients.any?
        mail(to:      recipients.to_a,
             subject: "A new #{@institution.service_name} item requires review")
      end
    end
  end

  ##
  # @param identity [Identity]
  #
  def password_reset(identity)
    @identity    = identity
    @institution = @identity.invitee.institution
    mail(to:      @identity.email,
         subject: "Reset your #{@institution.service_name} password")
  end

  ##
  # Used to test email delivery. See also the `mail:test` rake task.
  #
  def test(recipient)
    mail(to:      recipient,
         subject: "#{subject_prefix} Hello from IDEALS")
  end

  private

  def subject_prefix
    "[#{Rails.env.to_s.upcase}: IDEALS]"
  end
end
