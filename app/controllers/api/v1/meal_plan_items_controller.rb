# app/controllers/api/v1/meal_plan_items_controller.rb
module Api
  module V1
    class MealPlanItemsController < BaseController
      before_action :set_meal_plan
      before_action :set_meal_plan_item, only: [:destroy]

      def index
            @meal_plan_items = @meal_plan.meal_plan_items
                                        .includes(:plannable)
                                        .order(:scheduled_date, :meal_slot)
            
            render json: {
                meal_plan_items: @meal_plan_items.map { |item| meal_plan_item_json(item) }
            }, status: :ok
        end
      # POST /api/v1/meal_plans/:meal_plan_id/meal_plan_items
      def create
        @meal_plan_item = @meal_plan.meal_plan_items.new(meal_plan_item_params)
        assign_plannable

        if @meal_plan_item.save
          render json: {
            message: "Meal item added successfully",
            meal_plan_item: meal_plan_item_json(@meal_plan_item)
          }, status: :created
        else
          render json: {
            errors: @meal_plan_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/meal_plans/:meal_plan_id/meal_plan_items/:id
      def destroy
        item_name = @meal_plan_item.plannable.respond_to?(:title) ? 
                    @meal_plan_item.plannable.title : 
                    @meal_plan_item.plannable.item_name
        
        @meal_plan_item.destroy
        
        render json: {
          message: "#{item_name} removed from plan"
        }, status: :ok
      end

      # POST /api/v1/meal_plans/:meal_plan_id/meal_plan_items/add_to_shopping_list
      def add_to_shopping_list
        added_count = 0
        merged_count = 0

        @meal_plan.meal_plan_items.includes(plannable: :recipe_ingredients).each do |mpi|
          next unless mpi.plannable.present?

          case mpi.plannable
          when Recipe
            result = add_recipe_ingredients_to_shopping_list(mpi.plannable, @meal_plan)
            added_count += result[:added]
            merged_count += result[:merged]

          when Item
            existing_item = current_user.shopping_list_items
                                        .where(purchasable: mpi.plannable, is_purchased: false)
                                        .first
            
            if existing_item
              existing_qty = existing_item.quantity.to_s.to_f
              new_qty = (mpi.plannable.quantity || "1").to_f
              merged_qty = existing_qty + new_qty
              
              existing_item.update(quantity: merged_qty.to_s, meal_plan_id: @meal_plan.id)
              merged_count += 1
            else
              current_user.shopping_list_items.create!(
                purchasable: mpi.plannable,
                quantity: mpi.plannable.quantity || "1",
                is_purchased: false,
                meal_plan_id: @meal_plan.id
              )
              added_count += 1
            end
          end
        end

        message_parts = []
        message_parts << "#{added_count} new items added" if added_count > 0
        message_parts << "#{merged_count} items merged" if merged_count > 0
        
        render json: {
          message: message_parts.any? ? message_parts.join(', ') : "Shopping list updated",
          added_count: added_count,
          merged_count: merged_count
        }, status: :ok
      end

      private

      def set_meal_plan
        @meal_plan = MealPlan.find(params[:meal_plan_id])
      end

      def set_meal_plan_item
        @meal_plan_item = @meal_plan.meal_plan_items.find(params[:id])
      end

      def meal_plan_item_params
        params.require(:meal_plan_item).permit(
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
            item = Item.find_or_create_by(item_name: params[:new_item_name].strip) do |new_item|
              new_item.quantity = params[:new_item_quantity]&.strip if params[:new_item_quantity].present?
              new_item.user = current_user if Item.column_names.include?('user_id')
            end
            
            if params[:new_item_quantity].present? && !item.new_record?
              item.update(quantity: params[:new_item_quantity].strip)
            end
            
            @meal_plan_item.plannable = item
          else
            item = Item.find_by(id: params.dig(:meal_plan_item, :plannable_id))
            @meal_plan_item.plannable = item
          end
        end
      end

      def add_recipe_ingredients_to_shopping_list(recipe, meal_plan)
        added = 0
        merged = 0
        
        recipe.recipe_ingredients.includes(:ingredient).each do |ri|
          existing_item = current_user.shopping_list_items
                                      .where(purchasable: ri.ingredient, is_purchased: false)
                                      .first
          
          if existing_item
            existing_qty = existing_item.quantity.to_s.split.first.to_f
            new_qty = ri.quantity.to_f
            merged_qty = existing_qty + new_qty
            
            existing_item.update(
              quantity: "#{merged_qty} #{ri.unit}",
              meal_plan_id: meal_plan.id
            )
            merged += 1
          else
            current_user.shopping_list_items.create!(
              purchasable: ri.ingredient,
              quantity: "#{ri.quantity} #{ri.unit}",
              is_purchased: false,
              meal_plan_id: meal_plan.id
            )
            added += 1
          end
        end
        
        { added: added, merged: merged }
      end

      def meal_plan_item_json(item)
        {
          id: item.id,
          scheduled_date: item.scheduled_date,
          meal_slot: item.meal_slot,
          plannable_type: item.plannable_type,
          plannable_id: item.plannable_id,
          plannable: plannable_json(item.plannable)
        }
      end

      def plannable_json(plannable)
        return nil unless plannable
        
        case plannable
        when Recipe
          { id: plannable.id, title: plannable.title, type: 'Recipe' }
        when Item
          { id: plannable.id, item_name: plannable.item_name, quantity: plannable.quantity, type: 'Item' }
        else
          nil
        end
      end
    end
  end
end