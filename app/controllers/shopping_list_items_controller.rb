class ShoppingListItemsController < ApplicationController
  before_action :authenticate_user! 
  before_action :set_shopping_list_item, only: [:update, :destroy]
  before_action :load_items_and_ingredients, only: [:index]

  def create
  purchasable = find_or_create_purchasable
  
  if purchasable
    existing_item = current_user.shopping_list_items
                                .where(purchasable: purchasable, is_purchased: false)
                                .first
    
    if existing_item
      # Merge quantities - add new quantity to existing
      new_quantity = params[:shopping_list_item][:quantity].to_f
      existing_item.quantity = (existing_item.quantity.to_f + new_quantity).to_s
      
      if existing_item.save
        redirect_to shopping_list_items_path, notice: "Quantity updated for existing item (merged)."
      else
        redirect_to shopping_list_items_path, alert: "Failed to update item."
      end

    else

    @shopping_list_item = current_user.shopping_list_items.build(
      purchasable: purchasable,
      quantity: params[:shopping_list_item][:quantity],
      is_purchased: false
    )
    
    if @shopping_list_item.save
      redirect_to shopping_list_items_path, notice: "Item added to shopping list."
    else
      redirect_to shopping_list_items_path, alert: "Failed to add item."
    end
  end
  else
    redirect_to shopping_list_items_path, alert: "Please select or enter an item."
  end
end

  def index
    @shopping_list_items = current_user.shopping_list_items.includes(:purchasable, :payment)
  end

  def update
    if @shopping_list_item.update(shopping_list_item_params)
      redirect_to shopping_list_items_path, notice: "Item updated successfully."
    else
      redirect_to shopping_list_items_path, alert: "Failed to update item."
    end
  end

  def destroy
    @shopping_list_item.destroy
    redirect_to shopping_list_items_path, notice: "Item removed from shopping list."
  end

  def clear_purchased
    current_user.shopping_list_items.where(is_purchased: true).destroy_all
    redirect_to shopping_list_items_path, notice: "Purchased items cleared."
  end

  private

  def set_shopping_list_item
    @shopping_list_item = current_user.shopping_list_items.find(params[:id])
  end

  def shopping_list_item_params
    params.require(:shopping_list_item).permit(:is_purchased, :quantity, :item_type, :item_id, :ingredient_id, :manual_name)
  end
  def load_items_and_ingredients
    @items = Item.order(:item_name)
    @ingredients = Ingredient.order(:name)
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

end