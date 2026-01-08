# app/controllers/api/v1/meal_plans_controller.rb
module Api
  module V1
    class MealPlansController < BaseController
      before_action :set_meal_plan, only: [:show, :destroy]

      # GET /api/v1/meal_plans
      def index
        @meal_plans = MealPlan.includes(:user).order(created_at: :desc)
        render json: @meal_plans.map { |meal_plan|
          {
            id: meal_plan.id,
            category: meal_plan.category,
            start_date: meal_plan.start_date,
            end_date: meal_plan.end_date,
            user_id: meal_plan.user_id,
            created_at: meal_plan.created_at,
            updated_at: meal_plan.updated_at,
            user: {
              id: meal_plan.user.id,
              email: meal_plan.user.email
            }
          }
        }
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
  # Load meal plan items with their plannables
  meal_plan_items = @meal_plan.meal_plan_items
                               .includes(:plannable)
                               .order(:scheduled_date, :meal_slot)
  
  # Group items by date
  items_by_date = meal_plan_items.group_by { |item| item.scheduled_date.to_s }
  
  # Format the response with full item details
  formatted_items_by_date = {}
  items_by_date.each do |date, items|
    formatted_items_by_date[date] = items.map do |item|
      {
        id: item.id,
        scheduled_date: item.scheduled_date,
        meal_slot: item.meal_slot,
        plannable_type: item.plannable_type,
        plannable_id: item.plannable_id,
        plannable: item.plannable ? {
          id: item.plannable.id,
          title: item.plannable.respond_to?(:title) ? item.plannable.title : nil,
          item_name: item.plannable.respond_to?(:item_name) ? item.plannable.item_name : nil,
          quantity: item.plannable.respond_to?(:quantity) ? item.plannable.quantity : nil
        } : nil
      }
    end
  end
  
  # Get comments
  comments = @meal_plan.comments.includes(:user).map do |comment|
    {
      id: comment.id,
      content: comment.content,
      created_at: comment.created_at,
      user: {
        id: comment.user.id,
        email: comment.user.email
      }
    }
  end
  
  render json: {
    meal_plan: {
      id: @meal_plan.id,
      category: @meal_plan.category,
      start_date: @meal_plan.start_date,
      end_date: @meal_plan.end_date,
      user_id: @meal_plan.user_id,
      created_at: @meal_plan.created_at,
      updated_at: @meal_plan.updated_at
    },
    items_by_date: formatted_items_by_date,
    comments: comments
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