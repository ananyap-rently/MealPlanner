class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  helper_method :current_user
  allow_browser versions: :modern
  def current_user
    @current_user ||=User.first
  
  end
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
