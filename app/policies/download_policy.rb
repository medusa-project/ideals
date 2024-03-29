# frozen_string_literal: true

class DownloadPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This download resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param download [Download]
  #
  def initialize(request_context, download)
    super(request_context)
    @download = download
  end

  def file
    show
  end

  def show
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @download.institution
      return WRONG_SCOPE_RESULT
    elsif @download.expired # even sysadmins can't access expired downloads
      return { authorized: false,
               reason:     "This download is expired." }
    elsif @download.ip_address.present? && @download.ip_address != @client_ip
      return { authorized: false,
               reason:     "You are not authorized to access this download." }
    end
    AUTHORIZED_RESULT
  end

end
