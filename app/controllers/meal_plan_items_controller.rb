class MealPlanItemsController < ApplicationController
  before_action :set_meal_plan

  def create
    
    @meal_plan_item = @meal_plan.meal_plan_items.new(meal_plan_item_params)
    assign_plannable

    
    if params[:commit] == "Add to Plan"
    

      if @meal_plan_item.save
        slot = @meal_plan_item.meal_slot&.capitalize || "Item"
        date = @meal_plan_item.scheduled_date&.strftime('%A, %B %d') || "TBD"

redirect_to @meal_plan,
  notice: "✓ Meal item added successfully to #{date} - #{slot}!"

      else
        prepare_show_data
        flash.now[:alert] = "Could not save item. #{@meal_plan_item.errors.full_messages.join(', ')}"
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
    item_name = @item.plannable.respond_to?(:title) ? @item.plannable.title : @item.plannable.item_name
    @item.destroy
    redirect_to @meal_plan, notice: "✓ #{item_name} removed from plan."
  end

  
  def add_to_shopping_list
  added_count = 0
  merged_count = 0

  @meal_plan.meal_plan_items.includes(plannable: :recipe_ingredients).each do |mpi|
    next unless mpi.plannable.present?

    case mpi.plannable
    when Recipe
      result = add_recipe_ingredients_to_shopping_list(mpi.plannable)
      added_count += result[:added]
      merged_count += result[:merged]

    when Item
      # Check if item already exists in shopping list (unpurchased only)
      existing_item = current_user.shopping_list_items
                                  .where(purchasable: mpi.plannable, is_purchased: false)
                                  .first
      
      if existing_item
        # Merge quantities
        existing_qty = existing_item.quantity.to_s.to_f
        new_qty = (mpi.plannable.quantity || "1").to_f
        merged_qty = existing_qty + new_qty
        
        existing_item.update(quantity: merged_qty.to_s)
        merged_count += 1
      else
        # Create new item
        current_user.shopping_list_items.create!(
          purchasable: mpi.plannable,
          quantity: mpi.plannable.quantity || "1",
          is_purchased: false
        )
        added_count += 1
      end
    end
  end

  message = []
  message << "#{added_count} new items added" if added_count > 0
  message << "#{merged_count} items merged" if merged_count > 0
  
  redirect_to shopping_list_items_path,
              notice: message.any? ? "✓ #{message.join(', ')} to your shopping list!" : "✓ Shopping list updated!"
end

  private

  # for adding ingredients
  private

def add_recipe_ingredients_to_shopping_list(recipe)
  added = 0
  merged = 0
  
  recipe.recipe_ingredients.includes(:ingredient).each do |ri|
    # Check if ingredient already exists in shopping list (unpurchased only)
    existing_item = current_user.shopping_list_items
                                .where(purchasable: ri.ingredient, is_purchased: false)
                                .first
    
    if existing_item
      # Merge quantities: parse existing quantity and add new quantity
      existing_qty = existing_item.quantity.to_s.split.first.to_f  # Extract number from "2 cups"
      new_qty = ri.quantity.to_f
      merged_qty = existing_qty + new_qty
      
      # Update with merged quantity and keep the unit
      existing_item.update(quantity: "#{merged_qty} #{ri.unit}")
      merged += 1
    else
      # Create new item if it doesn't exist
      current_user.shopping_list_items.create!(
        purchasable: ri.ingredient,
        quantity: "#{ri.quantity} #{ri.unit}",
        is_purchased: false
      )
      added += 1
    end
  end
  
  { added: added, merged: merged }
end


  def set_meal_plan
    @meal_plan = MealPlan.find(params[:meal_plan_id])
  end

  def meal_plan_item_params
    params.fetch(:meal_plan_item).permit(
      :scheduled_date, 
      :meal_slot, 
      :plannable_type, 
      :plannable_id
    )
  end

  def assign_plannable
    type = params.dig(:meal_plan_item, :plannable_type)
    
    case type
    when "Recipe"
      recipe = Recipe.find_by(id: params.dig(:meal_plan_item, :plannable_id))
      @meal_plan_item.plannable = recipe
      
    when "Item"
      if params[:new_item_name].present?
        # Logic for "Create a new item using a text field"
        item = Item.find_or_create_by(item_name: params[:new_item_name].strip) do |new_item|
            new_item.quantity = params[:new_item_quantity]&.strip if params[:new_item_quantity].present?
            new_item.user = current_user if Item.column_names.include?('user_id')
        end
        
        # Update quantity if item already exists and new quantity provided
        if params[:new_item_quantity].present? && !item.new_record?
          item.update(quantity: params[:new_item_quantity].strip)
        end
        
        @meal_plan_item.plannable = item
      else
        # Logic for "Select an existing item from dropdown"
        item = Item.find_by(id: params.dig(:meal_plan_item, :plannable_id))
        @meal_plan_item.plannable = item
      end
    end
  end

  def prepare_show_data
    @recipes = Recipe.all.order(:title)
    @items = Item.all.order(:item_name)
    @comments = @meal_plan.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
    @meal_plan_item ||= @meal_plan.meal_plan_items.new
    # Group meal plan items by date for display
    @items_by_date = @meal_plan.meal_plan_items
                                .includes(:plannable)
                                .order(:scheduled_date, :meal_slot)
                                .group_by { |item| item.scheduled_date.to_date } 
  end
end