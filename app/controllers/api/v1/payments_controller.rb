# app/controllers/api/v1/payments_controller.rb
module Api
  module V1
    class PaymentsController < BaseController
      before_action :set_payment, only: [:update, :destroy]

      # GET /api/v1/payments
      def index
        @payments = current_user.payments.includes(shopping_list_item: :purchasable).order(created_at: :desc)
        
        # We return a structured JSON object containing both lists
        render json: {
          all_payments: @payments,
          pending: @payments.where(payment_status: 'pending'),
          completed: @payments.where(payment_status: 'completed')
        }
      end

      # POST /api/v1/payments
      def create
        @shopping_list_item = current_user.shopping_list_items.find(params[:shopping_list_item_id])
        
        if @shopping_list_item.payment.present?
          return render json: { error: "This item is already added to payments." }, status: :unprocessable_entity
        end

        @payment = Payment.new(
          shopping_list_item: @shopping_list_item,
          payment_status: 'pending'
        )

        if @payment.save
          render json: @payment, status: :created
        else
          render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/payments/:id
      def update
        @payment.update!(payment_params)
        render json: @payment, status: :ok
      end

      # DELETE /api/v1/payments/:id
      def destroy
        @payment.destroy
        head :no_content
      end

      # DELETE /api/v1/payments/clear_completed
      def clear_completed
        current_user.payments.where(payment_status: 'completed').destroy_all
        head :no_content
      end

      private

      def set_payment
        @payment = current_user.payments.find(params[:id])
      end

      def payment_params
        params.require(:payment).permit(:payment_status)
      end
    end
  end
end