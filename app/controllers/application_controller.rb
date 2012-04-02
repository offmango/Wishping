class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => "Unauthorized #{exception.action} of #{exception.subject}"
  end
  
end
