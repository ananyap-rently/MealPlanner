# app/controllers/tokens_controller.rb

class TokensController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :create_from_credentials]

  # POST /api/tokens
  # For browser: Converts current Devise session to OAuth token
  def create
    if current_user
      token = find_or_create_token(current_user)
      render json: {
        access_token: token.token,
        token_type: 'Bearer',
        expires_in: token.expires_in,
        refresh_token: token.refresh_token,
        created_at: token.created_at.to_i,
        scope: token.scopes.to_s
      }
    else
      render json: { error: 'Unauthorized - Please log in first' }, status: :unauthorized
    end
  end

  # POST /api/tokens/login
  # For Postman: Login with email/password to get token
  def create_from_credentials
    user = User.find_by(email: params[:email])
    
    if user&.valid_password?(params[:password])
      token = find_or_create_token(user)
      render json: {
        access_token: token.token,
        token_type: 'Bearer',
        expires_in: token.expires_in,
        refresh_token: token.refresh_token,
        created_at: token.created_at.to_i,
        scope: token.scopes.to_s
      }
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  # DELETE /api/tokens
  # Revoke current token
  def destroy
    if doorkeeper_token
      doorkeeper_token.revoke
      render json: { message: 'Token revoked successfully' }
    else
      render json: { error: 'No active token found' }, status: :not_found
    end
  end

  private

  def find_or_create_token(user)
    # Find or create OAuth application
    app = Doorkeeper::Application.find_or_create_by(name: 'Internal SPA') do |a|
      a.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
      a.scopes = 'read write'
      a.confidential = false
    end

    # Find existing valid token or create new one
    Doorkeeper::AccessToken.find_or_create_for(
      application: app,
      resource_owner: user,
      scopes: 'read write',
      expires_in: Doorkeeper.configuration.access_token_expires_in,
      use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
    )
  end

  def doorkeeper_token
    @doorkeeper_token ||= Doorkeeper::AccessToken.find_by(
      token: request.headers['Authorization']&.split(' ')&.last
    )
  end
end