# spec/requests/api/v1/payments_spec.rb
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
        it 'creates a new payment' do
          expect {
            post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          }.to change(Payment, :count).by(1)
        end
        
        it 'returns 201 created status' do
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          expect(response).to have_http_status(:created)
        end
        
        it 'returns the created payment as JSON' do
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['shopping_list_item_id']).to eq(shopping_list_item.id)
          expect(json_response['payment_status']).to eq('pending')
        end
        
        it 'sets payment_status to pending by default' do
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          
          expect(Payment.last.payment_status).to eq('pending')
        end
        
        it 'associates payment with shopping_list_item' do
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          
          expect(Payment.last.shopping_list_item).to eq(shopping_list_item)
        end
      end
      
      context 'when shopping_list_item already has a payment' do
        let!(:existing_payment) do
          create(:payment, shopping_list_item: shopping_list_item)
        end
        
        it 'does not create a new payment' do
          expect {
            post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          }.not_to change(Payment, :count)
        end
        
        it 'returns 422 unprocessable entity status' do
          post api_v1_payments_path, params: { shopping_list_item_id: shopping_list_item.id }, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
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
        
        # it 'raises RecordNotFound error' do
        #   expect {
        #     post api_v1_payments_path, params: { shopping_list_item_id: other_shopping_list_item.id }, headers: headers
        #   }.to raise_error(ActiveRecord::RecordNotFound)
        # end
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
      
    #   context 'with invalid parameters' do
    #     it 'raises an error for invalid status' do
    #       expect {
    #         patch api_v1_payment_path(payment), params: { payment: { payment_status: 'invalid' } }, headers: headers
    #     }.to raise_error(ArgumentError)
    #     end
    #   end
    # end
    context 'with invalid parameters' do
        it 'returns 422 unprocessable entity' do
            patch api_v1_payment_path(payment),
                params: { payment: { payment_status: 'invalid' } },
                headers: headers

            expect(response).to have_http_status(:unprocessable_entity)
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
      
      it 'returns 204 no content status' do
        delete api_v1_payment_path(payment), headers: headers
        expect(response).to have_http_status(:no_content)
      end
      
      it 'returns empty body' do
        delete api_v1_payment_path(payment), headers: headers
        expect(response.body).to be_empty
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
  
  describe 'DELETE /api/v1/payments/clear_completed' do
    context 'when user is authenticated' do
      
      
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
            delete clear_completed_api_v1_payments_path, headers: headers
          }.to change(Payment, :count).by(-2)
        end
        
        it 'does not destroy pending payments' do
          delete clear_completed_api_v1_payments_path, headers: headers
          
          expect(Payment.exists?(pending_payment.id)).to be true
        end
        
        it 'returns 204 no content status' do
          delete clear_completed_api_v1_payments_path, headers: headers
          expect(response).to have_http_status(:no_content)
        end
        
        it 'does not destroy other users completed payments' do
          other_shopping_list_item = create(:shopping_list_item, user: other_user)
          other_completed_payment = create(:payment, 
                                          shopping_list_item: other_shopping_list_item, 
                                          payment_status: 'completed')
          
          delete clear_completed_api_v1_payments_path, headers: headers
          
          expect(Payment.exists?(other_completed_payment.id)).to be true
        end
      end
      
      context 'when user has no completed payments' do
        let!(:pending_payment) do
          shopping_list_item = create(:shopping_list_item, user: user)
          create(:payment, shopping_list_item: shopping_list_item, payment_status: 'pending')
        end
        
        it 'does not destroy any payments' do
          expect {
            delete clear_completed_api_v1_payments_path, headers: headers
          }.not_to change(Payment, :count)
        end
        
        it 'returns 204 no content status' do
          delete clear_completed_api_v1_payments_path, headers: headers
          expect(response).to have_http_status(:no_content)
        end
      end
    end
    
    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        delete clear_completed_api_v1_payments_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end