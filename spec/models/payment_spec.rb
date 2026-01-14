# require 'rails_helper'

# RSpec.describe Payment, type: :model do
#   # 1. Basic Validation
#   it "is valid with a shopping_list_item and a payment_status" do
#     payment = build(:payment)
#     expect(payment).to be_valid
#   end

#   # 2. Association Test
#   it "is invalid without a shopping_list_item" do
#     payment = build(:payment, shopping_list_item: nil)
#     expect(payment).not_to be_valid
#   end

#   # 3. Status Test
#   it "is invalid without a payment_status" do
#     payment = build(:payment, payment_status: nil)
#     expect(payment).not_to be_valid
#   end

#   # 4. Testing Traits
#   describe "payment statuses" do
#     it "can be completed" do
#       payment = build(:payment, :completed)
#       expect(payment.payment_status).to eq("completed")
#     end

#     it "can be failed" do
#       payment = build(:payment, :failed)
#       expect(payment.payment_status).to eq("failed")
#     end
#   end
# end