# spec/requests/payments_controller_spec.rb
require 'rails_helper'

RSpec.describe PaymentsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:item) { create(:item) }
  let(:shopping_list_item_without_payment) { create(:shopping_list_item, user: user) }
  let(:shopping_list_item) { create(:shopping_list_item, user: user) }
  let(:payment) { create(:payment, shopping_list_item: shopping_list_item) }

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: user.password
      }
    }
  end

  describe 'GET /payments' do
    context 'when user is authenticated' do
      before do
        # sign_in user
        sign_in_as(user)
      end
      
      it 'returns a successful response' do
        get payments_path
        expect(response).to have_http_status(:success)
      end

      it 'renders the HTML shell' do
        get payments_path
        expect(response.body).to include('<html>')
        expect(response.body).to include('</html>')
      end
      it 'loads payments for the current user' do
        pending_payment = create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'pending')
        completed_payment = create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'completed')
        
        get payments_path
        expect(response).to have_http_status(:success)
        # The page loads successfully with user's payments
      end
    end

    

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        get payments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /payments' do
    context 'when user is authenticated' do
      before do
        # sign_in user
        sign_in_as(user)
      end
      
      context 'when item is not already in payments' do
        it 'creates a new payment and redirects' do
          new_shopping_item = create(:shopping_list_item, user: user)
          
          expect {
            post payments_path, params: { shopping_list_item_id: new_shopping_item.id }
          }.to change(Payment, :count).by(1)
          
          expect(response).to redirect_to(shopping_list_items_path)
          expect(flash[:notice]).to eq("✓ Item added to payments!")
        end

        it 'sets the status to pending by default' do
          new_shopping_item = create(:shopping_list_item, user: user)
          post payments_path, params: { shopping_list_item_id: new_shopping_item.id }
          expect(Payment.last.payment_status).to eq('pending')
        end
      end

      context 'when item is already added to payments' do
        it 'does not create a duplicate and alerts the user' do
          shopping_item_with_payment = create(:shopping_list_item, user: user)
          create(:payment, shopping_list_item: shopping_item_with_payment)
          
          expect {
            post payments_path, params: { shopping_list_item_id: shopping_item_with_payment.id }
          }.not_to change(Payment, :count)
          
          expect(response).to redirect_to(shopping_list_items_path)
          expect(flash[:alert]).to eq("This item is already added to payments.")
        end
      end

      context 'when shopping list item belongs to another user' do
        it 'raises record not found error' do
          other_shopping_item = create(:shopping_list_item, user: other_user)
          
       
        post payments_path, params: { shopping_list_item_id: other_shopping_item.id }
        expect(response).to have_http_status(:not_found)

        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        post payments_path, params: { shopping_list_item_id: shopping_list_item.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not create a payment' do
        new_shopping_item = create(:shopping_list_item, user: user)
        
        expect {
          post payments_path, params: { shopping_list_item_id: new_shopping_item.id }
        }.not_to change(Payment, :count)
      end
    end
  end

  describe 'PATCH /payments/:id' do
    context 'when user is the payment owner' do
      before do
        # sign_in user
        sign_in_as(user)
      end
      
      it 'updates the payment status and redirects' do
        payment_to_update = create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'pending')
        
        patch payment_path(payment_to_update), params: { payment: { payment_status: 'completed' } }
        
        payment_to_update.reload
        expect(payment_to_update.payment_status).to eq('completed')
        expect(response).to redirect_to(payments_path)
        expect(flash[:notice]).to eq("✓ Payment status updated to Completed.")
      end

      it 'sets success notice with capitalized status' do
        payment_to_update = create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'pending')
        
        patch payment_path(payment_to_update), params: { payment: { payment_status: 'completed' } }
        expect(flash[:notice]).to match(/Payment status updated to/)
      end
    end

    context 'when user is not the payment owner' do
      before do
        sign_in other_user
      end
      
      it 'raises record not found error' do
        user_payment = create(:payment, shopping_list_item: create(:shopping_list_item, user: user))
        
        
        patch payment_path(user_payment), params: { payment: { payment_status: 'completed' } }
        expect(response).to have_http_status(:not_found)

      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        patch payment_path(payment), params: { payment: { payment_status: 'completed' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /payments/:id' do
    context 'when user is the payment owner' do
      before do
        # sign_in user 
        sign_in_as(user)
      end
      
      it 'destroys the payment' do
        payment_to_destroy = create(:payment, shopping_list_item: create(:shopping_list_item, user: user))
        
        expect {
          delete payment_path(payment_to_destroy)
        }.to change(Payment, :count).by(-1)
      end

      it 'redirects to payments path' do
        payment_to_destroy = create(:payment, shopping_list_item: create(:shopping_list_item, user: user))
        delete payment_path(payment_to_destroy)
        expect(response).to redirect_to(payments_path)
      end

      it 'sets success notice' do
        payment_to_destroy = create(:payment, shopping_list_item: create(:shopping_list_item, user: user))
        delete payment_path(payment_to_destroy)
        expect(flash[:notice]).to match(/removed from payments/)
      end
    end

    context 'when user is not the payment owner' do
      before do
        sign_in other_user
      end
      
      it 'raises record not found error' do
        user_payment = create(:payment, shopping_list_item: create(:shopping_list_item, user: user))
        
   
    delete payment_path(user_payment)
    expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        delete payment_path(payment)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not destroy the payment' do
        payment
        expect {
          delete payment_path(payment)
        }.not_to change(Payment, :count)
      end
    end
  end

  describe 'DELETE /payments/clear_completed' do
    context 'when user is authenticated' do
      before do
        # sign_in user 
        sign_in_as(user)
      end
      
      it 'clears only completed payments for the user' do
        create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'completed')
        create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'completed')
        create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'pending')
        
        expect {
          delete clear_completed_payments_path
        }.to change { user.payments.where(payment_status: 'completed').count }.from(2).to(0)
      end

      it 'does not destroy pending payments' do
        create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'pending')
        pending_count = user.payments.where(payment_status: 'pending').count
        
        delete clear_completed_payments_path
        
        expect(user.payments.where(payment_status: 'pending').count).to eq(pending_count)
      end

      it 'redirects to payments path' do
        delete clear_completed_payments_path
        expect(response).to redirect_to(payments_path)
      end

      it 'sets success notice with count' do
        create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'completed')
        completed_count = user.payments.where(payment_status: 'completed').count
        
        delete clear_completed_payments_path
        expect(flash[:notice]).to eq("✓ #{completed_count} completed payment(s) cleared.")
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        delete clear_completed_payments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end