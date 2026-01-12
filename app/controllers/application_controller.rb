class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  
  before_action :check_role_selection
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  allow_browser versions: :modern
  
  private

  

  def check_role_selection
    # Skip if user is not logged in or on devise/role selection pages
    return unless user_signed_in?
    return if devise_controller?
    return if controller_name == 'role_selections'
     return if controller_name == 'pages'

   # Redirect to role selection if role not set
    if current_user.role.nil?
      session[:return_to] = request.fullpath
      redirect_to new_role_selection_path, alert: 'Please select your account type to continue.'
    end
  end

  def require_premium
    unless current_user&.premium?
      redirect_to root_path, alert: 'This feature is only available for premium users. Please upgrade your account.'
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :bio])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :bio])
  end
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
