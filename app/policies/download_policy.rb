class DownloadPolicy < ApplicationPolicy

  attr_reader :user, :role, :download

  ##
  # @param request_context [RequestContext]
  # @param download [Download]
  #
  def initialize(request_context, download)
    @client_ip       = request_context&.client_ip
    @client_hostname = request_context&.client_hostname
    @user            = request_context&.user
    @role            = request_context&.role_limit
    @download        = download
  end

  def file
    show
  end

  def show
    if download.expired # even sysadmins can't access expired downloads
      return { authorized: false,
               reason:     "This download is expired." }
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif download.ip_address.present? && download.ip_address != @client_ip
      return { authorized: false,
               reason:     "You are not authorized to access this download." }
    end
    AUTHORIZED_RESULT
  end

end
