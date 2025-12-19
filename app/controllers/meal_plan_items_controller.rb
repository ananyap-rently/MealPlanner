class MealPlanItemsController < ApplicationController
  before_action :set_meal_plan

  def create
    @meal_plan_item = @meal_plan.meal_plan_items.new(meal_plan_item_params)
    assign_plannable

    # 'commit' exists only when the "Add to Plan" button is clicked
    if params[:commit] == "Add to Plan"
      if @meal_plan_item.save
        redirect_to @meal_plan, notice: "Meal item added successfully."
      else
        prepare_show_data
        flash.now[:alert] = "Could not save item."
        render "meal_plans/show", status: :unprocessable_entity
      end
    else
      # This handles the radio button 'onchange' toggle
      prepare_show_data
      render "meal_plans/show"
    end
  end

  def destroy
    @item = @meal_plan.meal_plan_items.find(params[:id])
    @item.destroy
    redirect_to @meal_plan, notice: "Item removed from plan."
  end

  # Logic for "Would you like to add these to your shopping list?"
  def add_to_shopping_list
    @meal_plan.meal_plan_items.each do |mpi|
      # find_or_create prevents duplicates if the button is clicked twice
      current_user.shopping_list_items.find_or_create_by!(
        purchasable: mpi.plannable
      ) do |sli|
        sli.quantity = mpi.plannable.respond_to?(:quantity) ? mpi.plannable.quantity : "1"
        sli.is_purchased = false
      end
    end
    redirect_to shopping_list_items_path, notice: "Shopping list updated!"
  end

  private

  def set_meal_plan
    @meal_plan = MealPlan.find(params[:meal_plan_id])
  end

  def meal_plan_item_params
    params.fetch(:meal_plan_item, {}).permit(:scheduled_date, :meal_slot, :plannable_type, :plannable_id)
  end

  def assign_plannable
    type = params.dig(:meal_plan_item, :plannable_type)
    
    case type
    when "Recipe"
      @meal_plan_item.plannable = Recipe.find_by(id: params.dig(:meal_plan_item, :plannable_id))
    when "Item"
      if params[:new_item_name].present?
        # Logic for "Create a new item using a text field"
        item = Item.find_or_create_by(item_name: params[:new_item_name])
        item.update(quantity: params[:new_item_quantity]) if params[:new_item_quantity].present?
        @meal_plan_item.plannable = item
      else
        # Logic for "Select an existing item from dropdown"
        @meal_plan_item.plannable = Item.find_by(id: params.dig(:meal_plan_item, :plannable_id))
      end
    end
  end

  def prepare_show_data
    @recipes = Recipe.all
    @items = Item.all
    @comments = @meal_plan.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
    @items_by_date = @meal_plan.meal_plan_items.includes(:plannable).order(:scheduled_date, :meal_slot).group_by(&:scheduled_date)
  end
end