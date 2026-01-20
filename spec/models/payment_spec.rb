
require 'rails_helper'

RSpec.describe Payment, type: :model do
  
 

  describe "#item_name" do
    context "when linked to an Item" do
      it "returns the item_name from the purchasable" do
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

    # NEW: Added for 100% coverage of the 'else' branch
    context "when linked to an unknown type" do
      it "returns 'Unknown Item'" do
        shopping_list_item = build(:shopping_list_item, purchasable_type: "Other")
        payment = build(:payment, shopping_list_item: shopping_list_item)
        expect(payment.item_name).to eq("Unknown Item")
      end
    end
  end

  describe "ransackable methods" do
    it "defines correct ransackable attributes" do
      expected_attrs = ["id", "shopping_list_item_id", "payment_status"]
      expect(Payment.ransackable_attributes).to match_array(expected_attrs)
    end

    it "defines correct ransackable associations" do
      expect(Payment.ransackable_associations).to eq(["shopping_list_item"])
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
      payment.update(payment_status: 'completed')
      payment.update(payment_status: 'pending')
      expect(shopping_list_item.reload.is_purchased).to be false
    end

    
    it "does not trigger update if other attributes change" do
      expect(shopping_list_item).not_to receive(:update)
      payment.touch # Changes updated_at timestamp, but not payment_status
    end
  end
end