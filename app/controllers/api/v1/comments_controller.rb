# app/controllers/api/v1/comments_controller.rb
module Api
  module V1
    class CommentsController < BaseController
      # BaseController already handles authenticate_user!
        def index
            @commentable = find_commentable
            @comments = @commentable.comments.includes(:user)
            render json: @comments
        end
      # POST /api/v1/recipes/:recipe_id/comments
      # POST /api/v1/meal_plans/:meal_plan_id/comments
      def create
        @commentable = find_commentable
        @comment = @commentable.comments.build(comment_params)
        @comment.user = current_user

        # save! triggers ActiveRecord::RecordInvalid if content is blank, 
        # which BaseController catches
        @comment.save!
        render json: @comment, status: :created
      end

      # DELETE /api/v1/comments/:id
      def destroy
        @comment = current_user.comments.find(params[:id])
        @comment.destroy
        head :no_content # Returns 204 No Content status
      end

      private

      def find_commentable
        params.each_pair do |key, value|
          if (match = key.match(/(.+)_id$/))
            # Returns the object (e.g., Recipe or MealPlan)
            return match[1].classify.constantize.find(value)
          end
        end
        nil
      end

      def comment_params
        params.require(:comment).permit(:content)
      end
    end
  end
end