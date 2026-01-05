# app/controllers/api/v1/meal_plans_controller.rb
module Api
  module V1
    class MealPlansController < BaseController
      before_action :set_meal_plan, only: [:show, :destroy]

      # GET /api/v1/meal_plans
      def index
        @meal_plans = MealPlan.includes(:user).order(created_at: :desc)
        render json: @meal_plans
      end

      # POST /api/v1/meal_plans
      def create
        @meal_plan = current_user.meal_plans.new(meal_plan_params)
        
        # .save! triggers RecordInvalid exception which BaseController catches
        @meal_plan.save!
        render json: @meal_plan, status: :created
      end

      # GET /api/v1/meal_plans/:id
      def show
        # Organize data into a single response for the API client
        render json: {
          meal_plan: @meal_plan,
          items_by_date: @meal_plan.meal_plan_items
                                   .includes(:plannable)
                                   .order(:scheduled_date, :meal_slot)
                                   .group_by(&:scheduled_date),
          comments: @meal_plan.comments.includes(:user)
        }
      end

      # DELETE /api/v1/meal_plans/:id
      def destroy
        if @meal_plan.user == current_user
          @meal_plan.destroy
          head :no_content # Sends 204 No Content status
        else
          render json: { error: "You can only delete your own meal plans." }, 
                 status: :forbidden
        end
      end

      private

      def set_meal_plan
        @meal_plan = MealPlan.find(params[:id])
      end

      def meal_plan_params
        params.require(:meal_plan).permit(:category, :start_date)
      end
    end
  end
end