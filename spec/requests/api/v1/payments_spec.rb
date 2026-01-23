# # spec/requests/api/v1/payments_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::PaymentsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  # Create Doorkeeper tokens
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:other_token) { create(:doorkeeper_access_token, resource_owner_id: other_user.id) }

  # Create headers
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  let(:other_headers) { { "Authorization" => "Bearer #{other_token.token}", "Accept" => "application/json" } }

  # ...

  describe 'GET /api/v1/payments' do
    context 'when user is authenticated' do
      
      context 'when user has payments' do
        let!(:pending_payment) do
          shopping_list_item = create(:shopping_list_item, user: user)
          create(:payment, shopping_list_item: shopping_list_item, payment_status: 'pending')
        end
        
        let!(:completed_payment) do
          shopping_list_item = create(:shopping_list_item, user: user)
          create(:payment, shopping_list_item: shopping_list_item, payment_status: 'completed')
        end
        
        it 'returns a successful response' do
          get api_v1_payments_path, headers: headers
          expect(response).to have_http_status(:success)
        end
        
        it 'returns JSON content type' do
          get api_v1_payments_path, headers: headers
          expect(response.content_type).to match(%r{application/json})
        end
        
        it 'returns all payments in all_payments key' do
          get api_v1_payments_path, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['all_payments']).to be_present
          expect(json_response['all_payments'].size).to eq(2)
        end
        
        it 'returns pending payments in pending key' do
          get api_v1_payments_path, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['pending']).to be_present
          expect(json_response['pending'].size).to eq(1)
          expect(json_response['pending'].first['payment_status']).to eq('pending')
        end
        
        it 'returns completed payments in completed key' do
          get api_v1_payments_path, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['completed']).to be_present
          expect(json_response['completed'].size).to eq(1)
          expect(json_response['completed'].first['payment_status']).to eq('completed')
        end
        
        it 'includes item_name method in payment JSON' do
          get api_v1_payments_path, headers: headers
          json_response = JSON.parse(response.body)
          
          first_payment = json_response['all_payments'].first
          expect(first_payment).to have_key('item_name')
        end
        
        it 'includes shopping_list_item details' do
          get api_v1_payments_path, headers: headers
          json_response = JSON.parse(response.body)
          
          first_payment = json_response['all_payments'].first
          expect(first_payment['shopping_list_item']).to be_present
          expect(first_payment['shopping_list_item']).to have_key('quantity')
          expect(first_payment['shopping_list_item']).to have_key('purchasable_type')
        end
        
        it 'does not include other users payments' do
          other_shopping_list_item = create(:shopping_list_item, user: other_user)
          create(:payment, shopping_list_item: other_shopping_list_item)
          
          get api_v1_payments_path, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['all_payments'].size).to eq(2)
        end
      end
      
      context 'when user has no payments' do
        it 'returns empty arrays' do
          get api_v1_payments_path, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['all_payments']).to eq([])
          expect(json_response['pending']).to eq([])
          expect(json_response['completed']).to eq([])
        end
      end
    end
    
    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        get api_v1_payments_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe 'POST /api/v1/payments' do
    context 'when user is authenticated' do
    
      
      let(:shopping_list_item) { create(:shopping_list_item, user: user) }
      
      context 'with valid shopping_list_item_id' do
      end
      
      context 'when shopping_list_item already has a payment' do
        let!(:existing_payment) do
          create(:payment, shopping_list_item: shopping_list_item)
        end
        
        it 'does not create a new payment' do
          expect {
            post api_v1_payments_path,
     params: {
       shopping_list_item_id: shopping_list_item.id,
       payment_status: 'pending'
     },
     headers: headers
          }.not_to change(Payment, :count)
        end
        
        it 'returns 422 unprocessable entity status' do
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          expect(response).to have_http_status(:unprocessable_content)
        end
        
        it 'returns error message' do
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['error']).to eq("This item is already added to payments.")
        end
      end
      
      context 'when shopping_list_item does not exist' do
        it 'returns 404 status' do
        post api_v1_payments_path, params: { shopping_list_item_id: 99999 }, headers: headers
        expect(response).to have_http_status(:not_found) # Better than raise_error
    end
      end
      
      context 'when shopping_list_item belongs to another user' do
        let(:other_shopping_list_item) { create(:shopping_list_item, user: other_user) }
        
       
        it 'returns 404 not found' do
    post api_v1_payments_path,
        params: { shopping_list_item_id: other_shopping_list_item.id },
        headers: headers

    expect(response).to have_http_status(:not_found)
    end

      end
    end
    
    context 'when user is not authenticated' do
      let(:shopping_list_item) { create(:shopping_list_item, user: user) }
      
      it 'returns 401 unauthorized status' do
        post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'does not create a payment' do
        expect {
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }
        }.not_to change(Payment, :count)
      end
    end
  end
  
  describe 'PATCH /api/v1/payments/:id' do
    let(:shopping_list_item) { create(:shopping_list_item, user: user) }
    let(:payment) { create(:payment, shopping_list_item: shopping_list_item, payment_status: 'pending') }
    
    context 'when user is authenticated and owns the payment' do
      
      
      context 'with valid parameters' do
        it 'updates the payment status' do
          patch api_v1_payment_path(payment), params: { payment: { payment_status: 'completed' } }, headers: headers
          payment.reload
          
          expect(payment.payment_status).to eq('completed')
        end
        
        it 'returns 200 OK status' do
          patch api_v1_payment_path(payment), params: { payment: { payment_status: 'completed' } }, headers: headers
          expect(response).to have_http_status(:ok)
        end
        
        it 'returns the updated payment as JSON' do
          patch api_v1_payment_path(payment), params: { payment: { payment_status: 'completed' } }, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['payment_status']).to eq('completed')
        end
      end
      
  
    context 'with invalid parameters' do
        it 'returns 422 unprocessable entity' do
            patch api_v1_payment_path(payment),
                params: { payment: { payment_status: 'invalid' } },
                headers: headers

            expect(response).to have_http_status(:unprocessable_content)
        end
        end
    end
    context 'when payment belongs to another user' do
      
      
      it 'returns 404 or 403 status' do
        delete api_v1_payment_path(payment), headers: other_headers # USE other_headers
        expect(response).to have_http_status(:not_found) # Or :forbidden depending on controller
    end
    end
    
    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        patch api_v1_payment_path(payment), params: { payment: { payment_status: 'completed' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe 'DELETE /api/v1/payments/:id' do
    let(:shopping_list_item) { create(:shopping_list_item, user: user) }
    let!(:payment) { create(:payment, shopping_list_item: shopping_list_item) }
    
    context 'when user is authenticated and owns the payment' do
      
      
      it 'destroys the payment' do
        expect {
          delete api_v1_payment_path(payment), headers: headers
        }.to change(Payment, :count).by(-1)
      end
      
      it 'returns 200 ok status' do
      delete api_v1_payment_path(payment), headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'returns success message in body' do 
      delete api_v1_payment_path(payment), headers: headers
      json = JSON.parse(response.body)
      expect(json['message']).to eq("Payment deleted successfully")
      expect(json['id']).to eq(payment.id)
    end
    end
    
    context 'when payment belongs to another user' do
        it 'returns 404 not found' do
            delete api_v1_payment_path(payment), headers: other_headers

            expect(response).to have_http_status(:not_found)
        end

        it 'does not destroy the payment' do
            expect {
            delete api_v1_payment_path(payment), headers: other_headers
            }.not_to change(Payment, :count)
        end
        end

    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        delete api_v1_payment_path(payment)
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'does not destroy the payment' do
        expect {
          delete api_v1_payment_path(payment)
        }.not_to change(Payment, :count)
      end
    end
  end
  describe 'DELETE /api/v1/payments/:id' do
    let(:shopping_list_item) { create(:shopping_list_item, user: user) }
    let!(:payment) { create(:payment, shopping_list_item: shopping_list_item) }
    context 'when destruction fails and raises error' do
        it 'logs the error and returns 422' do
          payment = create(:payment, shopping_list_item: create(:shopping_list_item, user: user), deleted_at: Time.current)
          allow_any_instance_of(Payment).to receive(:really_destroy!).and_raise(StandardError.new("DB Error"))
          
          expect(Rails.logger).to receive(:error).with(/Permanent delete error/)
          delete permanent_api_v1_payment_path(payment), headers: headers
          
          expect(response).to have_http_status(:unprocessable_content)
          expect(JSON.parse(response.body)['error']).to eq('Failed to permanently delete payment')
        end
      end
    context 'when user is authenticated and owns the payment' do
      it 'soft deletes the payment (populates deleted_at)' do
        expect {
          delete api_v1_payment_path(payment), headers: headers
        }.to change { payment.reload.deleted_at }.from(nil)
      end

      it 'decreases the visible count but keeps the record in the database' do
        expect {
          delete api_v1_payment_path(payment), headers: headers
        }.to change(Payment, :count).by(-1) # Standard count ignores soft-deleted
        
        # Verify it still exists physically using unscoped
        expect(Payment.unscoped.exists?(payment.id)).to be true
      end

      it 'returns 200 ok status with success message' do
        delete api_v1_payment_path(payment), headers: headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq("Payment deleted successfully")
      end
    end
  end

  describe 'PATCH /api/v1/payments/:id/restore' do
    let(:shopping_list_item) { create(:shopping_list_item, user: user) }
    let!(:payment) { create(:payment, shopping_list_item: shopping_list_item, deleted_at: Time.current) }

    it 'restores a soft-deleted payment' do
      expect {
        patch restore_api_v1_payment_path(payment), headers: headers
      }.to change { payment.reload.deleted_at }.to(nil)
    end

    it 'makes the payment visible in the default scope again' do
      expect {
        patch restore_api_v1_payment_path(payment), headers: headers
      }.to change(Payment, :count).by(1)
    end
  end

  describe 'DELETE /api/v1/payments/:id/permanent' do
    let(:shopping_list_item) { create(:shopping_list_item, user: user) }
    let!(:payment) { create(:payment, shopping_list_item: shopping_list_item, deleted_at: Time.current) }

    it 'physically removes the record from the database' do
      expect {
        delete permanent_api_v1_payment_path(payment), headers: headers
      }.to change { Payment.unscoped.count }.by(-1)
      
      expect(Payment.unscoped.exists?(payment.id)).to be false
    end
  end

  describe 'DELETE /api/v1/payments/clear_completed' do
    let!(:completed_payment) { create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'completed') }
    let!(:pending_payment) { create(:payment, shopping_list_item: create(:shopping_list_item, user: user), payment_status: 'pending') }

    it 'soft deletes only completed payments' do
      delete clear_completed_api_v1_payments_path, headers: headers
      
      expect(completed_payment.reload.deleted_at).to be_present
      expect(pending_payment.reload.deleted_at).to be_nil
    end
  end

  describe 'GET /api/v1/payments/deleted' do
    let!(:deleted_payment) { create(:payment, shopping_list_item: create(:shopping_list_item, user: user), deleted_at: Time.current) }

    it 'returns only soft-deleted payments' do
      get deleted_api_v1_payments_path, headers: headers
      json_response = JSON.parse(response.body)
      
      expect(json_response['deleted_payments'].size).to eq(1)
      expect(json_response['deleted_payments'].first['id']).to eq(deleted_payment.id)
    end
  end
  
  describe 'DELETE #clear_completed' do
  context 'when user is authenticated' do
    
    before { sign_in user } 

    context 'when user has completed payments' do
      let!(:completed_payment_1) do
        shopping_list_item = create(:shopping_list_item, user: user)
        create(:payment, shopping_list_item: shopping_list_item, payment_status: 'completed')
      end
      
      let!(:completed_payment_2) do
        shopping_list_item = create(:shopping_list_item, user: user)
        create(:payment, shopping_list_item: shopping_list_item, payment_status: 'completed')
      end
      
      let!(:pending_payment) do
        shopping_list_item = create(:shopping_list_item, user: user)
        create(:payment, shopping_list_item: shopping_list_item, payment_status: 'pending')
      end
      
      it 'destroys all completed payments for the user' do
        expect {
          delete clear_completed_payments_path
        }.to change(Payment, :count).by(-2)
      end
      
      it 'does not destroy pending payments' do
        delete clear_completed_payments_path
        expect(Payment.exists?(pending_payment.id)).to be true
      end
      
      it 'redirects to payments index and shows success flash' do
        delete clear_completed_payments_path
        expect(response).to redirect_to(payments_path)
        expect(flash[:notice]).to match(/2 completed payment\(s\) cleared/)
      end
      
      it 'does not destroy other users completed payments' do
        other_user = create(:user)
        other_shopping_list_item = create(:shopping_list_item, user: other_user)
        other_completed_payment = create(:payment, 
                                        shopping_list_item: other_shopping_list_item, 
                                        payment_status: 'completed')
        
        delete clear_completed_payments_path
        
        expect(Payment.exists?(other_completed_payment.id)).to be true
      end
    end
    
    context 'when user has no completed payments' do
      it 'does not destroy any payments' do
        create(:payment, payment_status: 'pending', shopping_list_item: create(:shopping_list_item, user: user))
        
        expect {
          delete clear_completed_payments_path
        }.not_to change(Payment, :count)
      end
      
      it 'redirects to payments path' do
        delete clear_completed_payments_path
        expect(response).to redirect_to(payments_path)
      end
    end
  end
  
  context 'when user is not authenticated' do
    it 'redirects to sign in page (assuming Devise)' do
      delete clear_completed_payments_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
end
