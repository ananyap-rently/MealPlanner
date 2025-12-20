class MealPlanItemsController < ApplicationController
  before_action :set_meal_plan

  def create
    puts "DEBUG: Params received: #{params.inspect}" # Check your terminal for this!
    @meal_plan_item = @meal_plan.meal_plan_items.new(meal_plan_item_params)
    assign_plannable

    # 'commit' exists only when the "Add to Plan" button is clicked
    if params[:commit] == "Add to Plan"
      puts "DEBUG: meal_slot before save: #{@meal_plan_item.meal_slot.inspect}"

      if @meal_plan_item.save
         puts "DEBUG: meal_slot after save: #{@meal_plan_item.reload.meal_slot.inspect}"
     
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

  @meal_plan.meal_plan_items.includes(plannable: :recipe_ingredients).each do |mpi|
    next unless mpi.plannable.present?

    case mpi.plannable
    when Recipe
      add_recipe_ingredients_to_shopping_list(mpi.plannable)
      added_count += mpi.plannable.recipe_ingredients.count

    when Item
      shopping_item = current_user.shopping_list_items.find_or_create_by!(
        purchasable: mpi.plannable
      ) do |sli|
        sli.quantity = mpi.plannable.quantity || "1"
        sli.is_purchased = false
      end

      added_count += 1 if shopping_item.persisted?
    end
  end

  redirect_to shopping_list_items_path,
              notice: "✓ Ingredients added to your shopping list!"
end

  private

  # for adding ingredients
  def add_recipe_ingredients_to_shopping_list(recipe)
  recipe.recipe_ingredients.includes(:ingredient).each do |ri|
    current_user.shopping_list_items.find_or_create_by!(
      purchasable: ri.ingredient
    ) do |sli|
      sli.quantity = "#{ri.quantity} #{ri.unit}"
      sli.is_purchased = false
    end
  end
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
                                .group_by { |item| item.scheduled_date.to_date } # Add .to_date here
  end
end