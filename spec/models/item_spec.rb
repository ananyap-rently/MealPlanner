require 'rails_helper'

RSpec.describe Item, type: :model do
  describe 'Associations' do
    it { should have_many(:meal_plan_items) }
    it { should have_many(:shopping_list_items) }

    it 'verifies meal_plan_items association is polymorphic' do
      expect(Item.reflect_on_association(:meal_plan_items).options[:as]).to eq(:plannable)
    end

    it 'verifies shopping_list_items association is polymorphic' do
      expect(Item.reflect_on_association(:shopping_list_items).options[:as]).to eq(:purchasable)
    end
  end

  describe 'Validations' do
    it { should validate_presence_of(:item_name) }

    it 'is valid with valid attributes' do
      expect(build(:item)).to be_valid
    end
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "item_name", "quantity", "created_at"]
      expect(Item.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows no associations to be searchable' do
      expect(Item.ransackable_associations).to match_array([])
    end
  end
end