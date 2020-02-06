# frozen_string_literal: true

require "open-uri"
require "open_uri_redirections"

# defines and sends email
class IdealsMailer < ApplicationMailer
  default from: "ideals-gen@illinois.edu"

  def contact_help(params)
    subject = prepend_system_code("IDEALS] Help Request")
    @params = params
    mail(from:    @params["help-email"],
         to:      ["ideals-gen@illinois.edu",
                   @params["help-email"]],
         subject: subject)
  end

  def error(error_text)
    @error_text = error_text
    subject = prepend_system_code("IDEALS] System Error")
    mail(to: ::Configuration.instance.admin[:tech_mail_list].to_s,
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

  def prepend_system_code(subject)
    config = ::Configuration.instance
    if config.root_url_text.include?("demo")
      "[DEMO: " + subject
    elsif config.root_url_text.include?("localhost")
      "[LOCAL: " + subject
    else
      "[" + subject
    end
  end
end
