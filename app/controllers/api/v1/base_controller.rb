# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      # Skip CSRF token verification for API requests
      skip_before_action :verify_authenticity_token
      
        #before_action :doorkeeper_authorize! 
      # Use token-based or session authentication
      before_action :authenticate_user!
      
      # Return JSON errors
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      
      private
      
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