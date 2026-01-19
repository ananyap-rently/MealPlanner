# app/controllers/api/v1/summaries_controller.rb
module Api
  module V1
    class SummariesController < BaseController
      # Inherits authenticate_user! and error handling from BaseController
      before_action :ensure_premium_user
      # GET /api/v1/summaries
      def index
        render json: {
          user_stats: {
            name: current_user.name,
            recipes_count: current_user.recipes.count,
            meal_plans_count: current_user.meal_plans.count,
            comments_count: current_user.comments.count
          },
          recipes: recipe_summary_data,
          meal_plans: meal_plan_summary_data,
          shopping: shopping_summary_data
        }
      end

      # GET /api/v1/summaries/recipes
      def recipes
        render json: recipe_summary_data
      end

      # GET /api/v1/summaries/meal_plans
      def meal_plans
        render json: meal_plan_summary_data
      end

      # GET /api/v1/summaries/shopping
      def shopping
        render json: shopping_summary_data
      end

      private

      def recipe_summary_data
        {
          total_recipes: current_user.recipes.count,
          recipes_by_category: current_user.recipes.group(:title).count,
          most_used_recipes: current_user.recipes.joins(:meal_plan_items).group('recipes.id', 'recipes.title').order('COUNT(meal_plan_items.id) DESC').limit(10).count,
          recent_recipes: current_user.recipes.order(created_at: :desc).limit(5),
          total_ingredients_used: current_user.recipes.joins(recipe_ingredients: :ingredient).distinct.count('ingredients.id')
        }
      end

      def meal_plan_summary_data
        {
          total_meal_plans: current_user.meal_plans.count,
          active_meal_plans: current_user.meal_plans.where('start_date <= ?', Date.today).count,
          completed_meal_plans: current_user.meal_plans.where('start_date = ?', Date.today).count,
          upcoming_meals: current_user.meal_plans.joins(:meal_plan_items).where('meal_plan_items.scheduled_date >= ?', Date.today).order('meal_plan_items.scheduled_date ASC').limit(10).as_json(include: { meal_plan_items: { include: :plannable } }),
          meals_by_slot: current_user.meal_plans.joins(:meal_plan_items).group('meal_plan_items.meal_slot').count
        }
      end

      def shopping_summary_data
        total = current_user.shopping_list_items.count
        purchased = current_user.shopping_list_items.where(is_purchased: true).count
        {
          total_items: total,
          purchased_items: purchased,
          pending_items: current_user.shopping_list_items.where(is_purchased: false).count,
          completion_rate: total > 0 ? ((purchased.to_f / total) * 100).round(1) : 0,
          items_by_type: current_user.shopping_list_items.group(:purchasable_type).count
        }
      end
      private
      def ensure_premium_user
        unless current_user.premium? # Adjust this condition to match your logic
          render json: { 
            error: "Forbidden", 
            message: "This feature is only available to premium subscribers." 
          }, status: :forbidden # This returns the 403 status code
        end
      end
    end
  end
end