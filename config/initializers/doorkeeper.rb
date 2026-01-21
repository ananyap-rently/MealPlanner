# config/initializers/doorkeeper.rb

Doorkeeper.configure do
  # Integrate with Devise - authenticate the resource owner
  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  # Admin authenticator (for OAuth app management UI)
  admin_authenticator do
    current_user&.admin? || redirect_to(new_user_session_path)
  end

  # Define how to find user from credentials (for password grant)
  resource_owner_from_credentials do |_routes|
    user = User.find_by(email: params[:email] || params[:username])
    if user && user.valid_password?(params[:password])
      user
    else
      nil
    end
  end
  # ADD THIS LINE - it allows client credentials without resource owner
  skip_authorization do
    true
  end
  # Token expiration
  access_token_expires_in 2.hours
  authorization_code_expires_in 10.minutes

  # Enable refresh tokens
  use_refresh_token

  # Reuse access tokens
  reuse_access_token

  # Grant flows to enable
  #grant_flows %w[password authorization_code]
  grant_flows %w[password authorization_code client_credentials]

  # Skip authorization page for internal app
  skip_authorization do |resource_owner, client|
    client.application.name == 'Internal SPA'
  end

  # Scopes configuration
  default_scopes :read
  optional_scopes :write

  # Enforce scopes
  enforce_configured_scopes

  # API only mode
  api_only

  # Base controller for OAuth
  base_controller 'ActionController::API'
end