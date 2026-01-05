# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      before_action :set_user

      # GET /api/v1/profile
      def show
        render json: @user
      end

      # PATCH/PUT /api/v1/profile
      def update
        # .update! triggers an exception if validation fails, 
        # which BaseController catches via rescue_from
        @user.update!(user_params)
        render json: @user, status: :ok
      end

      # DELETE /api/v1/profile
      def destroy
        @user.destroy
        head :no_content
      end

      private

      def set_user
        @user = current_user
      end

      def user_params
        params.require(:user).permit(:name, :bio)
      end
    end
  end
end