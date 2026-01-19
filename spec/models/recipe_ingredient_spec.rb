require 'rails_helper'

RSpec.describe RecipeIngredient, type: :model do
  describe 'Associations' do
    it { should belong_to(:recipe) }
    it { should belong_to(:ingredient) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:quantity).with_message("can't be blank! ") }
    it { should validate_presence_of(:unit).with_message("can't be blank") }
    
    it 'is valid with valid attributes' do
      recipe_ingredient = build(:recipe_ingredient)
      expect(recipe_ingredient).to be_valid
    end
  end

  describe 'Callbacks: create_ingredient_from_name' do
    context 'when ingredient is missing but new_ingredient_name is present' do
      it 'creates and assigns a new ingredient' do
        recipe = create(:recipe)
        recipe_ingredient = RecipeIngredient.new(
          recipe: recipe,
          quantity: "1",
          unit: "cup",
          new_ingredient_name: "Fresh Basil"
        )

        expect { recipe_ingredient.valid? }.to change(Ingredient, :count).by(1)
        expect(recipe_ingredient.ingredient.name).to eq("Fresh Basil")
      end

      it 'finds an existing ingredient if the name already exists' do
        create(:ingredient, name: "Salt")
        recipe_ingredient = build(:recipe_ingredient, ingredient: nil, new_ingredient_name: "Salt")

        expect { recipe_ingredient.valid? }.not_to change(Ingredient, :count)
        expect(recipe_ingredient.ingredient.name).to eq("Salt")
      end
    end
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "quantity", "unit", "recipe_id", "ingredient_id", "created_at"]
      expect(RecipeIngredient.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows specific associations to be searchable' do
      expect(RecipeIngredient.ransackable_associations).to match_array(["ingredient", "recipe"])
    end
  end
end