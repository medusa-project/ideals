# frozen_string_literal: true

class IdealsMailer < ApplicationMailer
  NO_REPLY_ADDRESS = "ideals-noreply@illinois.edu"

  default from: ::Configuration.instance.website[:email]

  def contact_help(params)
    subject = "#{subject_prefix} IDEALS] Help Request"
    @params = params
    mail(from:    @params["help-email"],
         to:      [::Configuration.instance.website[:email],
                   @params["help-email"]],
         subject: subject)
  end

  def error(error_text)
    @error_text = error_text
    subject = "#{subject_prefix} IDEALS] System Error"
    mail(from: NO_REPLY_ADDRESS,
         to: ::Configuration.instance.admin[:tech_mail_list],
         subject: subject)
  end

  def account_activation(identity)
    @identity = identity
    mail(to: @identity.email, subject: "IDEALS account activation")
  end

  def password_reset(identity)
    @identity = identity
    mail(to: @identity.email, subject: "IDEALS password reset")
  end

  private

  def subject_prefix
    case Rails.env.to_sym
    when :production
      "[PRODUCTION:"
    when :demo
      "[DEMO:"
    else
      "[LOCAL:"
    end
  end
end
