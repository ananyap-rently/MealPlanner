# spec/requests/recipes_spec.rb
require 'rails_helper'

RSpec.describe 'Recipes', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:recipe) { create(:recipe, user: user) }
  let(:valid_attributes) do
    {
      title: 'Test Recipe',
      instructions: 'Test instructions',
      prep_time: 30,
      servings: 4
    }
  end
  let(:invalid_attributes) do
    {
      title: '',
      instructions: '',
      prep_time: nil,
      servings: nil
    }
  end

  describe 'GET /recipes' do
    it 'returns a success response' do
      get recipes_path
      expect(response).to be_successful
    end

    it 'displays all recipes' do
      recipe1 = create(:recipe, title: 'First Recipe')
      recipe2 = create(:recipe, title: 'Second Recipe')
      get recipes_path
      expect(response.body).to include('First Recipe')
      expect(response.body).to include('Second Recipe')
    end

    it 'does not require authentication' do
      get recipes_path
      expect(response).to be_successful
    end
  end

  describe 'GET /recipes/:id' do
    it 'returns a success response' do
      get recipe_path(recipe)
      expect(response).to be_successful
    end

    it 'displays the recipe details' do
      get recipe_path(recipe)
      expect(response.body).to include(recipe.title)
    end

    it 'displays associated comments' do
      comment = create(:comment, recipe: recipe, content: 'Great recipe!')
      get recipe_path(recipe)
      expect(response.body).to include('Great recipe!')
    end

    it 'does not require authentication' do
      get recipe_path(recipe)
      expect(response).to be_successful
    end
  end

  describe 'GET /recipes/new' do
    context 'when user is authenticated' do
      before { sign_in user }

      it 'returns a success response' do
        get new_recipe_path
        expect(response).to be_successful
      end

      it 'displays the new recipe form' do
        get new_recipe_path
        expect(response.body).to include('form')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        get new_recipe_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /recipes/:id/edit' do
    context 'when user is the recipe owner' do
      before { sign_in user }

      it 'returns a success response' do
        get edit_recipe_path(recipe)
        expect(response).to be_successful
      end

      it 'displays the edit recipe form' do
        get edit_recipe_path(recipe)
        expect(response.body).to include('form')
        expect(response.body).to include(recipe.title)
      end
    end

    context 'when user is not the recipe owner' do
      before { sign_in other_user }

      it 'redirects to recipes path' do
        get edit_recipe_path(recipe)
        expect(response).to redirect_to(recipes_path)
      end

      it 'sets an alert message' do
        get edit_recipe_path(recipe)
        follow_redirect!
        expect(response.body).to include('You are not authorized to perform this action')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        get edit_recipe_path(recipe)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /recipes' do
    context 'when user is authenticated' do
      before { sign_in user }

      context 'with valid params' do
        it 'creates a new Recipe' do
          expect {
            post recipes_path, params: { recipe: valid_attributes }
          }.to change(Recipe, :count).by(1)
        end

        it 'assigns the recipe to the current user' do
          post recipes_path, params: { recipe: valid_attributes }
          expect(Recipe.last.user).to eq(user)
        end

        it 'redirects to the created recipe' do
          post recipes_path, params: { recipe: valid_attributes }
          expect(response).to redirect_to(recipe_path(Recipe.last))
        end

        it 'sets a notice message' do
          post recipes_path, params: { recipe: valid_attributes }
          follow_redirect!
          expect(response.body).to include('Recipe created!')
        end
      end

      context 'with invalid params' do
        it 'does not create a new Recipe' do
          expect {
            post recipes_path, params: { recipe: invalid_attributes }
          }.not_to change(Recipe, :count)
        end

        it 'renders the new template' do
          post recipes_path, params: { recipe: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'displays error messages' do
          post recipes_path, params: { recipe: invalid_attributes }
          expect(response.body).to include('error') || expect(response.body).to include('invalid')
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        post recipes_path, params: { recipe: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not create a recipe' do
        expect {
          post recipes_path, params: { recipe: valid_attributes }
        }.not_to change(Recipe, :count)
      end
    end
  end

  describe 'PATCH /recipes/:id' do
    context 'when user is the recipe owner' do
      before { sign_in user }

      context 'with valid params' do
        let(:new_attributes) do
          { title: 'Updated Recipe', instructions: 'Updated instructions' }
        end

        it 'updates the requested recipe' do
          patch recipe_path(recipe), params: { recipe: new_attributes }
          recipe.reload
          expect(recipe.title).to eq('Updated Recipe')
          expect(recipe.instructions).to eq('Updated instructions')
        end

        it 'redirects to the recipe' do
          patch recipe_path(recipe), params: { recipe: new_attributes }
          expect(response).to redirect_to(recipe_path(recipe))
        end

        it 'sets a notice message' do
          patch recipe_path(recipe), params: { recipe: new_attributes }
          follow_redirect!
          expect(response.body).to include('Recipe updated successfully!')
        end
      end

      context 'with invalid params' do
        it 'does not update the recipe' do
          original_title = recipe.title
          patch recipe_path(recipe), params: { recipe: invalid_attributes }
          recipe.reload
          expect(recipe.title).to eq(original_title)
        end

        it 'returns unprocessable entity status' do
          patch recipe_path(recipe), params: { recipe: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'displays error messages' do
          patch recipe_path(recipe), params: { recipe: invalid_attributes }
          expect(response.body).to include('error') || expect(response.body).to include('invalid')
        end
      end
    end

    context 'when user is not the recipe owner' do
      before { sign_in other_user }

      it 'does not update the recipe' do
        original_title = recipe.title
        patch recipe_path(recipe), params: { recipe: { title: 'Hacked' } }
        recipe.reload
        expect(recipe.title).to eq(original_title)
      end

      it 'redirects to recipes path' do
        patch recipe_path(recipe), params: { recipe: valid_attributes }
        expect(response).to redirect_to(recipes_path)
      end

      it 'sets an alert message' do
        patch recipe_path(recipe), params: { recipe: valid_attributes }
        follow_redirect!
        expect(response.body).to include('You are not authorized to perform this action')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        patch recipe_path(recipe), params: { recipe: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /recipes/:id' do
    context 'when user is the recipe owner' do
      before { sign_in user }

      it 'destroys the requested recipe' do
        recipe_to_delete = create(:recipe, user: user)
        expect {
          delete recipe_path(recipe_to_delete)
        }.to change(Recipe, :count).by(-1)
      end

      it 'redirects to the recipes list' do
        delete recipe_path(recipe)
        expect(response).to redirect_to(recipes_path)
      end

      it 'sets a notice message' do
        delete recipe_path(recipe)
        follow_redirect!
        expect(response.body).to include('Recipe deleted')
      end

      it 'returns see_other status' do
        delete recipe_path(recipe)
        expect(response).to have_http_status(:see_other)
      end
    end

    context 'when user is not the recipe owner' do
      before { sign_in other_user }

      it 'does not destroy the recipe' do
        recipe_to_keep = create(:recipe, user: user)
        expect {
          delete recipe_path(recipe_to_keep)
        }.not_to change(Recipe, :count)
      end

      it 'redirects to recipes path' do
        delete recipe_path(recipe)
        expect(response).to redirect_to(recipes_path)
      end

      it 'sets an alert message' do
        delete recipe_path(recipe)
        follow_redirect!
        expect(response.body).to include('You are not authorized to perform this action')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        delete recipe_path(recipe)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not destroy the recipe' do
        recipe_to_keep = create(:recipe, user: user)
        expect {
          delete recipe_path(recipe_to_keep)
        }.not_to change(Recipe, :count)
      end
    end
  end

  describe 'nested resource operations' do
    context 'with tags' do
      before { sign_in user }

      it 'creates a recipe with tags' do
        tag1 = create(:tag)
        tag2 = create(:tag)
        
        post recipes_path, params: { 
          recipe: valid_attributes.merge(tag_ids: [tag1.id, tag2.id]) 
        }
        
        expect(Recipe.last.tags).to include(tag1, tag2)
      end

      it 'creates a recipe with a new tag' do
        post recipes_path, params: { 
          recipe: valid_attributes.merge(new_tag_name: 'Dessert') 
        }
        
        expect(Tag.find_by(name: 'Dessert')).to be_present
      end
    end

    context 'with ingredients' do
      before { sign_in user }

      it 'creates a recipe with ingredients' do
        ingredient = create(:ingredient)
        
        post recipes_path, params: { 
          recipe: valid_attributes.merge(
            recipe_ingredients_attributes: [
              { ingredient_id: ingredient.id, quantity: '2', unit: 'cups' }
            ]
          ) 
        }
        
        expect(Recipe.last.ingredients).to include(ingredient)
      end

      it 'creates a recipe with new ingredient' do
        post recipes_path, params: { 
          recipe: valid_attributes.merge(
            recipe_ingredients_attributes: [
              { new_ingredient_name: 'Sugar', quantity: '1', unit: 'cup' }
            ]
          ) 
        }
        
        expect(Ingredient.find_by(name: 'Sugar')).to be_present
      end
    end
  end
end