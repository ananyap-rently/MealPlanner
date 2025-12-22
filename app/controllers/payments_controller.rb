class PaymentsController < ApplicationController
  before_action :set_payment, only: [:update, :destroy]

  def index
    @payments = current_user.payments.includes(shopping_list_item: :purchasable).order(created_at: :desc)
    @pending_payments = @payments.where(payment_status: 'pending')
    @completed_payments = @payments.where(payment_status: 'completed')
  end

  def create
    @shopping_list_item = current_user.shopping_list_items.find(params[:shopping_list_item_id])
    
  
    if @shopping_list_item.payment.present?
      redirect_to shopping_list_items_path, alert: "This item is already added to payments."
      return
    end

    @payment = Payment.new(
      shopping_list_item: @shopping_list_item,
      payment_status: 'pending'
    )

    if @payment.save
      redirect_to shopping_list_items_path, notice: "✓ Item added to payments!"
    else
      redirect_to shopping_list_items_path, alert: "Failed to add item to payments."
    end
  end

  def update
    if @payment.update(payment_params)
      status = @payment.payment_status.capitalize
      redirect_to payments_path, notice: "✓ Payment status updated to #{status}."
    else
      redirect_to payments_path, alert: "Failed to update payment status."
    end
  end

  def destroy
    item_name = get_item_name(@payment.shopping_list_item)
    @payment.destroy
    redirect_to payments_path, notice: "✓ #{item_name} removed from payments."
  end

  def clear_completed
    completed_count = current_user.payments.where(payment_status: 'completed').count
    current_user.payments.where(payment_status: 'completed').destroy_all
    redirect_to payments_path, notice: "✓ #{completed_count} completed payment(s) cleared."
  end

  private

  def set_payment
    @payment = current_user.payments.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:payment_status)
  end

  def get_item_name(shopping_list_item)
    case shopping_list_item.purchasable_type
    when "Item"
      shopping_list_item.purchasable.item_name
    when "Ingredient"
      shopping_list_item.purchasable.name
    else
      "Item"
    end
  end
end