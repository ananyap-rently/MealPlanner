# spec/requests/recipes_controller_spec.rb
require 'rails_helper'

RSpec.describe RecipesController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:recipe) { create(:recipe, user: user) }
  let(:other_recipe) { create(:recipe, user: other_user) }
  
  describe 'GET /recipes' do
    context 'when recipes exist' do
      let!(:recipes) { create_list(:recipe, 3) }
      
      it 'returns a successful response' do
        get recipes_path
        expect(response).to have_http_status(:success)
      end
      
      it 'renders the HTML shell' do
        get recipes_path
        expect(response.body).to include('<html>')
        expect(response.body).to include('</html>')
      end
    end
    
    context 'when no authentication is required' do
      it 'allows unauthenticated access' do
        get recipes_path
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe 'GET /recipes/:id' do
    let(:recipe_with_comments) { create(:recipe, user: user) }
    
    context 'when recipe exists' do
      it 'returns a successful response' do
        get recipe_path(recipe_with_comments)
        expect(response).to have_http_status(:success)
      end
      
      it 'renders the HTML shell with recipe-show Stimulus controller' do
        get recipe_path(recipe_with_comments)
        expect(response.body).to include('data-controller="recipe-show"')
      end
      
      it 'includes recipe ID in data attributes for Stimulus' do
        get recipe_path(recipe_with_comments)
        expect(response.body).to include("data-recipe-show-recipe-id-value=\"#{recipe_with_comments.id}\"")
      end
      
      it 'includes loading state placeholder' do
        get recipe_path(recipe_with_comments)
        expect(response.body).to include('Loading recipe...')
      end
    end
    
    context 'when recipe does not exist' do
      it 'returns 404 not found status' do
        get recipe_path(id: 99999)
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context 'when no authentication is required' do
      it 'allows unauthenticated access' do
        get recipe_path(recipe_with_comments)
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe 'GET /recipes/new' do
    context 'when user is authenticated' do
      before { sign_in user }
      
      it 'returns a successful response' do
        get new_recipe_path
        expect(response).to have_http_status(:success)
      end
      
      it 'renders the HTML shell with recipe-form Stimulus controller' do
        get new_recipe_path
        expect(response.body).to include('data-controller="recipe-form')
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
      
      it 'returns a successful response' do
        get edit_recipe_path(recipe)
        expect(response).to have_http_status(:success)
      end
      
      it 'renders the HTML shell with recipe-form Stimulus controller' do
        get edit_recipe_path(recipe)
        expect(response.body).to include('data-controller="recipe-form')
      end
      
      it 'includes recipe ID in data attributes for Stimulus' do
        get edit_recipe_path(recipe)
        expect(response.body).to include("data-recipe-form-recipe-id-value=\"#{recipe.id}\"")
      end
      
      it 'displays edit mode indicator' do
        get edit_recipe_path(recipe)
        expect(response.body).to include('Edit Recipe')
      end
    end
    
    context 'when user is not the recipe owner' do
      before { sign_in other_user }
      
      it 'redirects to recipes index' do
        get edit_recipe_path(recipe)
        expect(response).to redirect_to(recipes_path)
      end
      
      it 'sets an alert flash message' do
        get edit_recipe_path(recipe)
        expect(flash[:alert]).to eq("You are not authorized to perform this action")
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
    let(:ingredient) { create(:ingredient) }
    let(:tag) { create(:tag) }
    
    let(:valid_attributes) do
      {
        title: 'Chocolate Cake',
        instructions: 'Mix and bake',
        prep_time: 30,
        servings: 8,
        tag_ids: [tag.id],
        recipe_ingredients_attributes: [
          {
            ingredient_id: ingredient.id,
            quantity: '2',
            unit: 'cups'
          }
        ]
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
    
    context 'when user is authenticated' do
      before { sign_in user }
      
      context 'with valid parameters' do
        it 'creates a new recipe' do
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
          expect(response).to redirect_to(Recipe.last)
        end
        
        it 'sets a success notice' do
          post recipes_path, params: { recipe: valid_attributes }
          expect(flash[:notice]).to eq("Recipe created!")
        end
        
        it 'creates recipe with associated ingredients' do
          post recipes_path, params: { recipe: valid_attributes }
          expect(Recipe.last.recipe_ingredients.count).to eq(1)
        end
        
        it 'creates recipe with associated tags' do
          post recipes_path, params: { recipe: valid_attributes }
          expect(Recipe.last.tags).to include(tag)
        end
      end
      
      context 'with invalid parameters' do
        it 'does not create a new recipe' do
          expect {
            post recipes_path, params: { recipe: invalid_attributes }
          }.not_to change(Recipe, :count)
        end
        
        it 'returns unprocessable content status' do
          post recipes_path, params: { recipe: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
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
  
  describe 'PATCH/PUT /recipes/:id' do
    let(:new_attributes) do
      {
        title: 'Updated Recipe Title',
        instructions: 'Updated instructions',
        prep_time: 45,
        servings: 6
      }
    end
    
    let(:invalid_attributes) do
      {
        title: '',
        instructions: ''
      }
    end
    
    context 'when user is the recipe owner' do
      before { sign_in user }
      
      context 'with valid parameters' do
        it 'updates the requested recipe' do
          patch recipe_path(recipe), params: { recipe: new_attributes }
          recipe.reload
          expect(recipe.title).to eq('Updated Recipe Title')
          expect(recipe.prep_time).to eq(45)
        end
        
        it 'redirects to the recipe' do
          patch recipe_path(recipe), params: { recipe: new_attributes }
          expect(response).to redirect_to(recipe)
        end
        
        it 'sets a success notice' do
          patch recipe_path(recipe), params: { recipe: new_attributes }
          expect(flash[:notice]).to eq("Recipe updated successfully!")
        end
      end
      
      context 'with invalid parameters' do
        it 'does not update the recipe' do
          original_title = recipe.title
          patch recipe_path(recipe), params: { recipe: invalid_attributes }
          recipe.reload
          expect(recipe.title).to eq(original_title)
        end
        
        it 'returns unprocessable entity status' do
          patch recipe_path(recipe), params: { recipe: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
    
    context 'when user is not the recipe owner' do
      before { sign_in other_user }
      
      it 'does not update the recipe' do
        original_title = recipe.title
        patch recipe_path(recipe), params: { recipe: new_attributes }
        recipe.reload
        expect(recipe.title).to eq(original_title)
      end
      
      it 'redirects to recipes index' do
        patch recipe_path(recipe), params: { recipe: new_attributes }
        expect(response).to redirect_to(recipes_path)
      end
      
      it 'sets an alert flash message' do
        patch recipe_path(recipe), params: { recipe: new_attributes }
        expect(flash[:alert]).to eq("You are not authorized to perform this action")
      end
    end
    
    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        patch recipe_path(recipe), params: { recipe: new_attributes }
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
      
      it 'redirects to recipes index' do
        delete recipe_path(recipe)
        expect(response).to redirect_to(recipes_path)
      end
      
      it 'sets a success notice' do
        delete recipe_path(recipe)
        expect(flash[:notice]).to eq("Recipe deleted")
      end
      
      it 'returns see_other status' do
        delete recipe_path(recipe)
        expect(response).to have_http_status(:see_other)
      end
    end
    
    context 'when user is not the recipe owner' do
      before { sign_in other_user }
      
      it 'does not destroy the recipe' do
        recipe
        expect {
          delete recipe_path(recipe)
        }.not_to change(Recipe, :count)
      end
      
      it 'redirects to recipes index' do
        delete recipe_path(recipe)
        expect(response).to redirect_to(recipes_path)
      end
      
      it 'sets an alert flash message' do
        delete recipe_path(recipe)
        expect(flash[:alert]).to eq("You are not authorized to perform this action")
      end
    end
    
    context 'when user is not authenticated' do
      it 'redirects to sign in page' do
        delete recipe_path(recipe)
        expect(response).to redirect_to(new_user_session_path)
      end
      
      it 'does not destroy the recipe' do
        recipe
        expect {
          delete recipe_path(recipe)
        }.not_to change(Recipe, :count)
      end
    end
  end
end