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
    if item.primary_collection&.administering_users&.any?
      recipients = item.primary_collection.administering_users.map(&:email)
      mail(to:      recipients,
           subject: "A new #{@institution.service_name} item requires review")
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
