# frozen_string_literal: true

class IdealsMailer < ApplicationMailer
  # This address is not arbitrary;
  # see https://answers.uillinois.edu/illinois/page.php?id=47888
  NO_REPLY_ADDRESS = "no-reply@illinois.edu"

  default from: "IDEALS @ Illinois <#{::Configuration.instance.mail[:from]}>"

  ##
  # @param exception [Exception]
  # @param url [String] Request URL.
  # @param user [User] Current user.
  # @return [String]
  #
  def self.error_body(exception, url: nil, user: nil)
    io = StringIO.new
    io << "Error"
    io << " on #{url}" if url
    io << ":\nClass: #{exception.class}\n"
    io << "Message: #{exception.message}\n"
    io << "Time: #{Time.now.iso8601}\n"
    io << "User: #{user.name}\n" if user
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
    @identity = identity
    mail(to: @identity.email, subject: "Register your IDEALS account")
  end

  ##
  # Notifies the given invitee that their request to register has been denied.
  #
  # @param invitee [Invitee]
  #
  def account_denied(invitee)
    @invitee = invitee
    mail(to: invitee.email, subject: "Your IDEALS account request")
  end

  ##
  # Notifies the given invitee that their registration has been received, and
  # contains a link to activate their account.
  #
  # @param identity [Identity]
  #
  def account_registered(identity)
    @identity = identity
    mail(to: identity.email, subject: "You're ready to log in to IDEALS!")
  end

  ##
  # Notifies sysadmins that a user has requested to register and needs to be
  # approved to do so. Used in conjunction with {account_request_received}.
  #
  # @param invitee [Invitee]
  #
  def account_request_action_required(invitee)
    config       = ::Configuration.instance
    @invitee_url = "#{config.website[:base_url]}/invitees/#{invitee.id}"
    mail(to: [config.mail[:from]],
         subject: "#{subject_prefix} Action required on a new IDEALS user")
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
    @invitee = invitee
    mail(to: invitee.email, subject: "Your IDEALS account request")
  end

  def error(error_text)
    @error_text = error_text
    mail(reply_to: NO_REPLY_ADDRESS,
         to:       ::Configuration.instance.admin[:tech_mail_list],
         subject:  "#{subject_prefix} System Error")
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
    @identity = identity
    mail(to: @identity.email, subject: "Register for an IDEALS account")
  end

  ##
  # @param item [Item]
  #
  def item_submitted(item)
    config    = ::Configuration.instance
    @item_url = item_url(item, host: config.website[:base_url])
    if item.primary_collection&.managing_users&.any?
      recipients = item.primary_collection.managing_users.map(&:email)
    else
      recipients = config.admin[:tech_mail_list] # TODO: use a different config key
    end
    mail(reply_to: NO_REPLY_ADDRESS,
         to:       recipients,
         subject:  "A new IDEALS item requires review")
  end

  ##
  # @param identity [Identity]
  #
  def password_reset(identity)
    @identity = identity
    mail(to: @identity.email, subject: "Reset your IDEALS password")
  end

  ##
  # Used to test email delivery. See also the `mail:test` rake task.
  #
  def test(recipient)
    mail(to: recipient, subject: "#{subject_prefix} Hello from IDEALS")
  end

  private

  def subject_prefix
    "[#{Rails.env.to_s.upcase}: IDEALS]"
  end
end
