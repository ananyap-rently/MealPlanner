# spec/requests/admin/payments_spec.rb
require 'rails_helper'

RSpec.describe "Admin::Payments", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:shopping_list_item) { create(:shopping_list_item) }
  let!(:payment) { create(:payment, shopping_list_item: shopping_list_item, payment_status: "pending") }

  before do
    sign_in admin_user
  end

  describe "Index Page and Scopes" do
    it "renders the index page successfully" do
      get admin_payments_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Item ##{shopping_list_item.id}")
    end

    it "uses the 'pending' scope" do
      completed_payment = create(:payment, :completed)
      get admin_payments_path, params: { scope: 'pending' }
      expect(response.body).to include(payment.id.to_s)
      expect(response.body).not_to include(completed_payment.id.to_s)
    end

    # it "uses the 'completed' scope" do
    #   completed_payment = create(:payment, :completed)
    #   get admin_payments_path, params: { scope: 'completed' }
    #   expect(response.body).to include(completed_payment.id.to_s)
    #   expect(response.body).not_to include(payment.id.to_s)
    # end
    it "uses the 'completed' scope" do
  completed_payment = create(:payment, :completed)

  get admin_payments_path, params: { scope: 'completed' }

  expect(response.body).to include("Item ##{completed_payment.shopping_list_item.id}")
  expect(response.body).not_to include("Item ##{payment.shopping_list_item.id}")
end

   
  end

  describe "Filters" do
    it "filters by payment_status" do
      get admin_payments_path, params: { q: { payment_status_eq: "pending" } }
      expect(response.body).to include(payment.id.to_s)
    end
  end

  describe "Batch Actions" do
    it "marks selected payments as Completed" do
      post batch_action_admin_payments_path, params: {
        batch_action: "mark_as_completed",
        collection_selection: [payment.id]
      }
      expect(payment.reload.payment_status).to eq("Completed")
      expect(flash[:notice]).to match(/marked as Completed/)
    end

    it "marks selected payments as Pending" do
      payment.update(payment_status: "Completed")
      post batch_action_admin_payments_path, params: {
        batch_action: "mark_as_pending",
        collection_selection: [payment.id]
      }
      expect(payment.reload.payment_status).to eq("Pending")
      expect(flash[:notice]).to match(/marked as Pending/)
    end
  end


end