# app/controllers/api/v1/base_controller.rb

module Api
  module V1
    class BaseController < ActionController::API
      # Skip CSRF token verification (API doesn't use CSRF tokens)
      # (This is automatic in ActionController::API, but explicit is fine)
      
      # Doorkeeper authorization - requires valid OAuth token
       include Pagy::Backend
      before_action :doorkeeper_authorize!

      # Return JSON format
      respond_to :json

      # Rescue from errors
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

      private
       def pagination_dict(pagy)
        {
          current_page: pagy.page,
          next_page:    pagy.next,
          prev_page:    pagy.prev,
          total_pages:  pagy.pages,
          total_count:  pagy.count,
          per_page:     pagy.limit # In Pagy 9.x, use 'limit' instead of 'items'
        }
      end
     


      # Get current user from OAuth token
      def current_user
        return @current_user if defined?(@current_user)
        
        @current_user = if doorkeeper_token
          User.find_by(id: doorkeeper_token.resource_owner_id)
        else
          nil
        end
      end

      # Handle unauthorized requests
      def doorkeeper_unauthorized_render_options(error: nil)
        {
          json: { 
            error: 'Not authorized',
            message: 'You need to provide a valid access token'
          },
          status: :unauthorized
        }
      end

      # Handle forbidden requests
      def doorkeeper_forbidden_render_options(error: nil)
        {
          json: { 
            error: 'Forbidden',
            message: 'You do not have permission to access this resource'
          },
          status: :forbidden
        }
      end

      # Error handlers
      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { errors: exception.record.errors.full_messages }, 
               status: :unprocessable_entity
      end
    end
  end
end