class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  helper_method :current_user, :logged_in?

  include CanCan::ControllerAdditions

  private

  def current_user
    begin
      if session[:user_id]
        @current_user = User::Shibboleth.find(session[:user_id]) || User::Identity.find(session[:user_id])
      end
    rescue ActiveRecord::RecordNotFound
      session[:user_id] = nil
    end
  end

  def set_current_user(user)
    @current_user = user
    session[:current_user_id] = user.id
  end

  def unset_current_user
    @current_user = nil
    session[:current_user_id] = nil
  end

  def logged_in?
    current_user.present?
  end

  def require_logged_in
    unless logged_in?
      session[:login_return_uri] = request.env['REQUEST_URI']
      redirect_to(login_path)
    end
  end


end
