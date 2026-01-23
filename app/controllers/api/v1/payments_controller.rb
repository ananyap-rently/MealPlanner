module Api
  module V1
    class PaymentsController < BaseController
      before_action :set_payment, only: [:update, :destroy]
      before_action :set_deleted_payment, only: [:restore, :permanent]

      # GET /api/v1/payments
      def index
        @payments = current_user.payments.includes(shopping_list_item: :purchasable)
        
        render json: {
          all_payments: render_payment_json(@payments),
          pending: render_payment_json(@payments.pending),
          completed: render_payment_json(@payments.completed)
        }
      end

      # GET /api/v1/payments/deleted
      def deleted
        @payments = current_user.payments
                                .unscoped
                                .where.not(deleted_at: nil)
                                .includes(shopping_list_item: :purchasable)
                                .order(deleted_at: :desc)
        
        render json: {
          deleted_payments: render_deleted_payment_json(@payments)
        }
      end

      # POST /api/v1/payments
      def create
        @shopping_list_item = current_user.shopping_list_items.find(params[:shopping_list_item_id])
        
        # Check if payment already exists (including soft-deleted ones)
        existing_payment = Payment.unscoped.find_by(shopping_list_item_id: @shopping_list_item.id)
        
        if existing_payment&.deleted_at.nil?
          return render json: { error: "This item is already added to payments." }, status: :unprocessable_entity
        end
        
        @payment = Payment.new(
          shopping_list_item: @shopping_list_item,
          payment_status: 'pending'
        )
        
        if @payment.save
          render json: render_single_payment_json(@payment), status: :created
        else
          render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/payments/:id
      def update
        if @payment.update(payment_params)
          render json: render_single_payment_json(@payment), status: :ok
        else
          render json: { errors: @payment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/payments/:id (soft delete)
      def destroy
        if @payment.soft_delete
          render json: { 
            message: 'Payment deleted successfully',
            id: @payment.id
          }, status: :ok
        else
          render json: { error: 'Failed to delete payment' }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/payments/:id/restore
      def restore
        if @payment.restore
          @payment.reload
          
          render json: { 
            message: 'Payment restored successfully',
            payment: render_single_payment_json(@payment)
          }, status: :ok
        else
          render json: { error: 'Failed to restore payment' }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/payments/clear_completed
      def clear_completed
        completed_payments = current_user.payments.completed
        count = completed_payments.count
        
        completed_payments.each(&:soft_delete)
        
        render json: { 
          message: "#{count} completed payments cleared",
          count: count
        }, status: :ok
      end

      # DELETE /api/v1/payments/:id/permanent
      def permanent
        begin
          # Use really_destroy! to permanently delete
          if @payment.really_destroy!
            render json: { 
              message: 'Payment permanently deleted' 
            }, status: :ok
          else
            render json: { error: 'Failed to permanently delete payment' }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error "Permanent delete error: #{e.message}"
          render json: { error: 'Failed to permanently delete payment' }, status: :unprocessable_entity
        end
      end

      private

      def render_payment_json(payments)
        payments.as_json(
          methods: [:item_name],
          include: { 
            shopping_list_item: { 
              only: [:id, :quantity, :purchasable_type, :is_purchased] 
            } 
          }
        )
      end

      def render_deleted_payment_json(payments)
        payments.as_json(
          methods: [:item_name],
          include: { 
            shopping_list_item: { 
              only: [:id, :quantity, :purchasable_type] 
            }
          },
          # Include deleted_at timestamp
          only: [:id, :payment_status, :created_at, :updated_at, :deleted_at, :shopping_list_item_id]
        )
      end

      def render_single_payment_json(payment)
        payment.as_json(
          methods: [:item_name],
          include: { 
            shopping_list_item: { 
              only: [:id, :quantity, :purchasable_type, :is_purchased] 
            } 
          }
        )
      end

      # For active payments only (not soft-deleted)
      def set_payment
        @payment = current_user.payments.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Payment not found' }, status: :not_found
      end

      # For deleted payments (used in restore and permanent)
      def set_deleted_payment
        @payment = current_user.payments
                                .unscoped
                                .where.not(deleted_at: nil)
                                .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Deleted payment not found' }, status: :not_found
      end

      def payment_params
        params.require(:payment).permit(:payment_status)
      end
    end
  end
end