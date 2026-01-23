# app/controllers/api/v1/shopping_list_items_controller.rb
module Api
  module V1
    class ShoppingListItemsController < BaseController
      before_action :set_shopping_list_item, only: [:update, :destroy]

      # GET /api/v1/shopping_list_items
      def index
          items_scope = current_user.shopping_list_items
                                    .includes(:purchasable, :payment)
                                    .order(created_at: :desc)

          @pagy, @shopping_list_items = pagy(items_scope)

          render json: {
            shopping_list_items: @shopping_list_items.map { |item|
              {
                id: item.id,
                quantity: item.quantity,
                is_purchased: item.is_purchased,
                purchasable_type: item.purchasable_type,
                purchasable_id: item.purchasable_id,
                has_payment: item.payment.present?,
                created_at: item.created_at,
                purchasable: item.purchasable ? purchasable_json(item.purchasable, item.purchasable_type) : nil
              }
            },
            meta: pagy_metadata(@pagy)
          }
        end

      
      # POST /api/v1/shopping_list_items
      def create
        purchasable = find_or_create_purchasable
        
        unless purchasable
          return render json: { error: "Please select or enter an item." }, status: :bad_request
        end

        # Check for existing unpurchased item
        existing_item = current_user.shopping_list_items
                                    .where(purchasable: purchasable, is_purchased: false)
                                    .first

        if existing_item
          # Merge quantities
          new_quantity = params[:shopping_list_item][:quantity].to_f
          existing_item.quantity = (existing_item.quantity.to_f + new_quantity).to_s
          existing_item.save!
          
          render json: format_item_json(existing_item), status: :ok
        else
          @shopping_list_item = current_user.shopping_list_items.build(
            purchasable: purchasable,
            quantity: params[:shopping_list_item][:quantity],
            is_purchased: false
          )
          @shopping_list_item.save!
          
          render json: format_item_json(@shopping_list_item), status: :created
        end
      end

      # PATCH/PUT /api/v1/shopping_list_items/:id
      def update
        @shopping_list_item.update!(shopping_list_item_params)
        render json: format_item_json(@shopping_list_item), status: :ok
      end

      # DELETE /api/v1/shopping_list_items/:id
      def destroy
        @shopping_list_item.destroy
        head :no_content
      end

      # DELETE /api/v1/shopping_list_items/clear_purchased
      def clear_purchased
        current_user.shopping_list_items.where(is_purchased: true).destroy_all
        head :no_content
      end

      private

      def set_shopping_list_item
        @shopping_list_item = current_user.shopping_list_items.find(params[:id])
      end

      def shopping_list_item_params
        params.require(:shopping_list_item).permit(
          :is_purchased, :quantity, :item_type, :item_id, 
          :ingredient_id, :manual_name
        )
      end

      def find_or_create_purchasable
        item_type = params[:shopping_list_item][:item_type]
        manual_name = params[:shopping_list_item][:manual_name]&.strip

        case item_type
        when 'existing_item'
          Item.find_by(id: params[:shopping_list_item][:item_id])
        when 'existing_ingredient'
          Ingredient.find_by(id: params[:shopping_list_item][:ingredient_id])
        when 'manual_item'
          return nil if manual_name.blank?
          Item.find_or_create_by(item_name: manual_name)
        when 'manual_ingredient'
          return nil if manual_name.blank?
          Ingredient.find_or_create_by(name: manual_name)
        end
      end

      def format_item_json(item)
        {
          id: item.id,
          quantity: item.quantity,
          is_purchased: item.is_purchased,
          purchasable_type: item.purchasable_type,
          purchasable_id: item.purchasable_id,
          created_at: item.created_at,
          purchasable: item.purchasable ? purchasable_json(item.purchasable, item.purchasable_type) : nil
        }
      end

      def purchasable_json(purchasable, type)
        case type
        when 'Recipe'
          { id: purchasable.id, title: purchasable.title }
        when 'Item'
          { id: purchasable.id, item_name: purchasable.item_name }
        when 'Ingredient'
          { id: purchasable.id, name: purchasable.name }
        else
          nil
        end
      end
    end
  end
end