class MealPlansController < ApplicationController
  before_action :set_meal_plan, only: [ :show, :destroy]

  def index
    @meal_plans = MealPlan.includes(:user).order(created_at: :desc)
    @meal_plan = MealPlan.new
  end

  def create
    @meal_plan = current_user.meal_plans.new(meal_plan_params)
    
    if @meal_plan.save
      redirect_to @meal_plan, notice: "Meal plan created successfully."
    else
      @meal_plans = MealPlan.includes(:user).order(created_at: :desc)
      render :index
    end
  end

  def show
  
    @meal_plan_item = @meal_plan.meal_plan_items.new
    @recipes = Recipe.all
    @items = Item.all
    
    @items_by_date = @meal_plan.meal_plan_items
                                .includes(:plannable)
                                .order(:scheduled_date, :meal_slot)
                                .group_by(&:scheduled_date)
    
    @comments = @meal_plan.comments.includes(:user)
    @comment = Comment.new
  end

  def destroy
    if @meal_plan.user == current_user
      @meal_plan.destroy
      redirect_to meal_plans_path, notice: "Meal plan deleted successfully."
    else
      redirect_to meal_plans_path, alert: "You can only delete your own meal plans."
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