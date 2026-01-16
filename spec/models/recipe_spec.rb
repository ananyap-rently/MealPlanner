# spec/models/recipe_spec.rb
require 'rails_helper'

RSpec.describe Recipe, type: :model do
  # Association tests
  describe 'associations' do
    it 'belongs to user' do
      association = Recipe.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'has many recipe_ingredients with dependent destroy' do
      association = Recipe.reflect_on_association(:recipe_ingredients)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it 'has many ingredients through recipe_ingredients' do
      association = Recipe.reflect_on_association(:ingredients)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:recipe_ingredients)
    end

    it 'has and belongs to many tags' do
      association = Recipe.reflect_on_association(:tags)
      expect(association.macro).to eq(:has_and_belongs_to_many)
    end

    it 'has many meal_plan_items' do
      association = Recipe.reflect_on_association(:meal_plan_items)
      expect(association.macro).to eq(:has_many)
    end

    it 'has many comments with dependent destroy' do
      association = Recipe.reflect_on_association(:comments)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  # Validation tests
  describe 'validations' do
    # it 'is invalid without a title' do
    #   recipe = build(:recipe, title: nil)
    #   expect(recipe).not_to be_valid
    #   expect(recipe.errors[:title]).to include("can't be blank")
    # end
    it 'is invalid without a title' do
      recipe = build(:recipe)
      recipe.title = nil

      expect(recipe).not_to be_valid
      expect(recipe.errors[:title]).to include("can't be blank")
    end


    it 'is valid with a title' do
      recipe = build(:recipe)
      expect(recipe).to be_valid
    end
  end

  # Nested attributes tests
  describe 'nested attributes' do
    it 'accepts nested attributes for recipe_ingredients' do
      expect(Recipe.nested_attributes_options.keys).to include(:recipe_ingredients)
    end

    it 'allows destroy for nested recipe_ingredients' do
      options = Recipe.nested_attributes_options[:recipe_ingredients]
      expect(options[:allow_destroy]).to be true
    end
  end

  # Ransackable attributes tests
  describe '.ransackable_attributes' do
    it 'returns the correct searchable attributes' do
      expected_attributes = ["id", "title", "prep_time", "servings", "user_id", "created_at"]
      expect(Recipe.ransackable_attributes).to match_array(expected_attributes)
    end
  end

  # Ransackable associations tests
  describe '.ransackable_associations' do
    it 'returns the correct searchable associations' do
      expected_associations = ["user", "ingredients", "tags"]
      expect(Recipe.ransackable_associations).to match_array(expected_associations)
    end
  end

  # Callback tests - Tag creation from name
  describe 'after_save callback' do
    let(:user) { create(:user) }
    let(:recipe) { build(:recipe, user: user) }

    context 'when new_tag_name is present' do
      it 'creates a new tag and associates it with the recipe' do
        recipe.new_tag_name = 'Vegan'
        expect { recipe.save }.to change(Tag, :count).by(1)
        expect(recipe.tags.pluck(:tag_name)).to include('Vegan')
      end

      it 'finds existing tag and associates it with the recipe' do
        existing_tag = create(:tag, tag_name: 'Dessert')
        recipe.new_tag_name = 'Dessert'
        
        expect { recipe.save }.not_to change(Tag, :count)
        expect(recipe.tags).to include(existing_tag)
      end

      it 'strips whitespace from tag name' do
        recipe.new_tag_name = '  Breakfast  '
        recipe.save
        
        expect(recipe.tags.pluck(:tag_name)).to include('Breakfast')
      end

      it 'does not add duplicate tags to the same recipe' do
        tag = create(:tag, tag_name: 'Italian')
        recipe.tags << tag
        recipe.save
        
        recipe.new_tag_name = 'Italian'
        recipe.save
        
        expect(recipe.tags.where(tag_name: 'Italian').count).to eq(1)
      end
    end

    context 'when new_tag_name is blank' do
      it 'does not create a new tag' do
        recipe.new_tag_name = ''
        expect { recipe.save }.not_to change(Tag, :count)
      end

      it 'does not create a tag when new_tag_name is nil' do
        recipe.new_tag_name = nil
        expect { recipe.save }.not_to change(Tag, :count)
      end
    end
  end

  # Nested attributes functionality tests
  describe 'creating recipe with nested ingredients' do
    let(:user) { create(:user) }
    let(:ingredient1) { create(:ingredient) }
    let(:ingredient2) { create(:ingredient) }

    it 'creates recipe with nested recipe_ingredients' do
      recipe = Recipe.create(
        title: 'Cake',
        user: user,
        prep_time: 30,
        servings: 8,
        recipe_ingredients_attributes: [
          { ingredient_id: ingredient1.id, quantity: '2', unit: 'cups' },
          { ingredient_id: ingredient2.id, quantity: '1', unit: 'cup' }
        ]
      )

      expect(recipe.reload.recipe_ingredients.count).to eq(2)
      expect(recipe.ingredients).to include(ingredient1, ingredient2)
    end

    it 'updates recipe and destroys recipe_ingredients when allow_destroy is true' do
      recipe = create(:recipe, user: user)
      recipe_ingredient = create(:recipe_ingredient, recipe: recipe)

      recipe.update(
        recipe_ingredients_attributes: [
          { id: recipe_ingredient.id, _destroy: '1' }
        ]
      )

      expect(recipe.reload.recipe_ingredients.count).to eq(0)
    end
  end

  # Polymorphic association tests
  describe 'polymorphic associations' do
    let(:recipe) { create(:recipe) }

    # it 'can have comments' do
    #   comment = create(:comment, commentable: recipe)
    #   expect(recipe.comments).to include(comment)
    # end
    it 'can have comments' do
      comment = recipe.comments.create!(
        content: "Great!",
        user: create(:user)
      )

      expect(recipe.comments).to include(comment)
    end

    it 'can be added to meal plans' do
      meal_plan = create(:meal_plan, user: recipe.user)
       meal_plan_item = create(:meal_plan_item, plannable: recipe, meal_plan: meal_plan)
      expect(recipe.meal_plan_items).to include(meal_plan_item)
    end
  end

  # Dependent destroy tests
  describe 'dependent destroy' do
    let(:recipe) { create(:recipe) }

    it 'destroys associated recipe_ingredients when recipe is destroyed' do
      create(:recipe_ingredient, recipe: recipe)
      
      expect { recipe.destroy }.to change(RecipeIngredient, :count).by(-1)
    end

    # it 'destroys associated comments when recipe is destroyed' do
    #   create(:comment, commentable: recipe)
      
    #   expect { recipe.destroy }.to change(Comment, :count).by(-1)
    # end
    it 'destroys associated comments when recipe is destroyed' do
      recipe.comments.create!(
        content: "Nice recipe!",
        user: create(:user)
      )

      expect { recipe.destroy }.to change(Comment, :count).by(-1)
    end

    it 'does not destroy associated tags when recipe is destroyed' do
      tag = create(:tag)
      recipe.tags << tag
      
      expect { recipe.destroy }.not_to change(Tag, :count)
    end
  end

  # Test actual functionality with associations
  describe 'working with ingredients' do
    let(:recipe) { create(:recipe) }
    let(:ingredient) { create(:ingredient) }

    it 'can add ingredients through recipe_ingredients' do
      recipe.recipe_ingredients.create(ingredient: ingredient, quantity: 2, unit: 'cups')
      
      expect(recipe.ingredients).to include(ingredient)
      expect(recipe.recipe_ingredients.first.quantity).to eq(2)
      expect(recipe.recipe_ingredients.first.unit).to eq('cups')
    end
  end

  # Test actual functionality with tags
  describe 'working with tags' do
    let(:recipe) { create(:recipe) }
    let(:tag) { create(:tag, tag_name: 'Vegetarian') }

    it 'can add tags to recipe' do
      recipe.tags << tag
      
      expect(recipe.tags).to include(tag)
      expect(tag.recipes).to include(recipe)
    end

    it 'can have multiple tags' do
      tag1 = create(:tag, tag_name: 'Vegan')
      tag2 = create(:tag, tag_name: 'Quick')
      
      recipe.tags << [tag1, tag2]
      
      expect(recipe.tags.count).to eq(2)
      expect(recipe.tags).to include(tag1, tag2)
    end
  end
end