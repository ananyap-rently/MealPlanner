class SummariesController < ApplicationController
  
  
  def index

    load_recipe_summary
    load_meal_plan_summary
    load_shopping_summary
  
  end
  
  def recipes
    
    load_recipe_summary
  end
  
  def meal_plans
    
    load_meal_plan_summary
  end
  
  def shopping
  
    load_shopping_summary
  end
  
  
  private
  
  def load_recipe_summary
    @total_recipes = current_user.recipes.count
    @recipes_by_category = current_user.recipes.group(:title).count
    @most_used_recipes = current_user.recipes
                                     .joins(:meal_plan_items)
                                     .group('recipes.id', 'recipes.title')
                                     .order('COUNT(meal_plan_items.id) DESC')
                                     .limit(10)
                                     .count
    @recent_recipes = current_user.recipes.order(created_at: :desc).limit(5)
    @total_ingredients_used = current_user.recipes
                                      .joins(recipe_ingredients: :ingredient)
                                      .distinct
                                      .count('ingredients.id')

  end
  
  def load_meal_plan_summary
    @total_meal_plans = current_user.meal_plans.count
    @active_meal_plans = current_user.meal_plans.where('start_date <= ?', Date.today).count
    @completed_meal_plans = current_user.meal_plans.where('start_date = ?', Date.today).count
    
    @upcoming_meals = current_user.meal_plans
                                  .joins(:meal_plan_items)
                                  .where('meal_plan_items.scheduled_date >= ?', Date.today)
                                  .order('meal_plan_items.scheduled_date ASC')
                                  .limit(10)
                                  .includes(meal_plan_items: :plannable)
    
    @meals_by_slot = current_user.meal_plans
                                 .joins(:meal_plan_items)
                                 .group('meal_plan_items.meal_slot')
                                 .count
    
    @current_week_meals = current_user.meal_plans
                                      .joins(:meal_plan_items)
                                      .where('meal_plan_items.scheduled_date BETWEEN ? AND ?', 
                                             Date.today.beginning_of_week, 
                                             Date.today.end_of_week)
                                      .count
  end
  
  def load_shopping_summary
    @total_shopping_items = current_user.shopping_list_items.count
    @purchased_items = current_user.shopping_list_items.where(is_purchased: true).count
    @pending_items = current_user.shopping_list_items.where(is_purchased: false).count
    @purchase_completion_rate = @total_shopping_items > 0 ? 
                                 ((@purchased_items.to_f / @total_shopping_items) * 100).round(1) : 0
    
    @items_by_type = current_user.shopping_list_items.group(:purchasable_type).count
    
    @most_purchased_items = current_user.shopping_list_items
                                        .where(is_purchased: true)
                                        .group(:purchasable_type, :purchasable_id)
                                        .count
                                        .sort_by { |_, count| -count }
                                        .first(10)
                                        .map do |key, count|
                                          type, id = key
                                          item = type.constantize.find_by(id: id)
                                          { item: item, count: count, type: type }
                                        end
    
    @recent_purchases = current_user.shopping_list_items
                                    .where(is_purchased: true)
                                    .order(updated_at: :desc)
                                    .limit(10)
                                    .includes(:purchasable)
  end
end