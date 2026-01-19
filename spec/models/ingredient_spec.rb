require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe 'Associations' do
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:recipes).through(:recipe_ingredients) }
    it { should have_many(:shopping_list_items) }
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "name", "created_at"]
      expect(Ingredient.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows specific associations to be searchable' do
      expected_assoc = ["recipe_ingredients", "recipes"]
      expect(Ingredient.ransackable_associations).to match_array(expected_assoc)
    end
  end

  describe 'Polymorphic Association' do
    it 'can be associated with shopping list items as purchasable' do
      # This assumes you have a factory for shopping_list_item
      ingredient = create(:ingredient)
      # You can verify the type/as relationship here if needed
      expect(Ingredient.reflect_on_association(:shopping_list_items).options[:as]).to eq(:purchasable)
    end
  end
end