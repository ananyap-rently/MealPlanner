require 'rails_helper'

RSpec.describe ShoppingListItem, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:meal_plan).optional }
    it { should belong_to(:purchasable) }
    it { should have_one(:payment).dependent(:destroy) }
  end

  describe 'Scopes' do
    describe '.pending' do
      it 'returns only items where is_purchased is false' do
        pending_item = create(:shopping_list_item, is_purchased: false)
        purchased_item = create(:shopping_list_item, is_purchased: true)

        expect(ShoppingListItem.pending).to include(pending_item)
        expect(ShoppingListItem.pending).not_to include(purchased_item)
      end
    end
  end

  describe 'Polymorphic Behavior' do
    it 'can point to an Ingredient' do
      item = build(:shopping_list_item, :for_ingredient)
      expect(item.purchasable_type).to eq('Ingredient')
    end

    it 'can point to a generic Item' do
      item = build(:shopping_list_item, :for_item)
      expect(item.purchasable_type).to eq('Item')
    end
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "user_id", "purchasable_id", "purchasable_type", "quantity", "is_purchased", "meal_plan_id", "created_at"]
      expect(ShoppingListItem.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows specific associations to be searchable' do
      expect(ShoppingListItem.ransackable_associations).to match_array(["user", "meal_plan", "purchasable"])
    end
  end
end