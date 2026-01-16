require 'rails_helper'

RSpec.describe Payment, type: :model do
  
  describe "validations" do
    it "is valid with a shopping_list_item and valid status" do
      payment = build(:payment) # Uses FactoryBot
      expect(payment).to be_valid
    end

    it "is invalid without a payment_status" do
      payment = build(:payment, payment_status: nil)
      payment.valid?
      expect(payment.errors[:payment_status]).to include("can't be blank")
    end

    it "is invalid with a status other than pending or completed" do
      payment = build(:payment, payment_status: "failed")
      payment.valid?
      expect(payment.errors[:payment_status]).to include("is not included in the list")
    end
  end

  describe "associations" do
    it "belongs to a shopping_list_item" do
      association = described_class.reflect_on_association(:shopping_list_item)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has a user through shopping_list_item" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:has_one)
      expect(association.options[:through]).to eq(:shopping_list_item)
    end
  end

  describe "scopes" do
    let!(:pending_payment) { create(:payment, payment_status: 'pending') }
    let!(:completed_payment) { create(:payment, payment_status: 'completed') }

    it ".pending returns only pending payments" do
      # Note: Your model scope uses 'Pending' (Capitalized), 
      # ensure your database values and scope casing match!
      expect(Payment.pending).to include(pending_payment)
      expect(Payment.pending).not_to include(completed_payment)
    end

    it ".completed returns only completed payments" do
      expect(Payment.completed).to include(completed_payment)
      expect(Payment.completed).not_to include(pending_payment)
    end
  end

  describe "#item_name" do
    context "when linked to an Item" do
      it "returns the item_name from the purchasable" do
        # We manually stub/build the nested objects to test logic
        item = double("Item", item_name: "Apples")
        shopping_list_item = build(:shopping_list_item, purchasable_type: "Item")
        allow(shopping_list_item).to receive(:purchasable).and_return(item)
        
        payment = build(:payment, shopping_list_item: shopping_list_item)
        
        expect(payment.item_name).to eq("Apples")
      end
    end

    context "when linked to an Ingredient" do
      it "returns the name from the purchasable" do
        ingredient = double("Ingredient", name: "Salt")
        shopping_list_item = build(:shopping_list_item, purchasable_type: "Ingredient")
        allow(shopping_list_item).to receive(:purchasable).and_return(ingredient)
        
        payment = build(:payment, shopping_list_item: shopping_list_item)
        
        expect(payment.item_name).to eq("Salt")
      end
    end
  end

  describe "callbacks" do
    let(:shopping_list_item) { create(:shopping_list_item, is_purchased: false) }
    let(:payment) { create(:payment, shopping_list_item: shopping_list_item, payment_status: 'pending') }

    it "marks the shopping list item as purchased when payment is completed" do
      payment.update(payment_status: 'completed')
      expect(shopping_list_item.reload.is_purchased).to be true
    end

    it "unmarks the shopping list item as purchased if status reverts to pending" do
  # First complete the payment
  payment.update(payment_status: 'completed')
  expect(shopping_list_item.reload.is_purchased).to be true

  # Then revert back to pending
  payment.update(payment_status: 'pending')
  expect(shopping_list_item.reload.is_purchased).to be false
end

  end
end