class ShoppingListItemsController < ApplicationController
  before_action :set_shopping_list_item, only: [:update, :destroy]

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
    params.require(:shopping_list_item).permit(:is_purchased, :quantity)
  end
end