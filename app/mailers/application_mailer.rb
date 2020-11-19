# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "IDEALS <#{::Configuration.instance.mail[:from]}>",
          reply_to: ::Configuration.instance.mail[:reply_to]
  layout "mailer"
end
