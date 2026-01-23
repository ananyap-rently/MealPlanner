# spec/requests/api/v1/recipes_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::RecipesController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  # --- DOORKEEPER SETUP ---
  # Create tokens for both users
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:other_token) { create(:doorkeeper_access_token, resource_owner_id: other_user.id) }
  
  # Define headers for both users
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  let(:other_headers) { { "Authorization" => "Bearer #{other_token.token}", "Accept" => "application/json" } }
  # ------------------------
  
  describe 'GET /api/v1/recipes' do
    context 'when recipes exist' do
      let!(:recipes) { create_list(:recipe, 3) }
      
      it 'returns a successful response' do
        get api_v1_recipes_path, headers: headers
        expect(response).to have_http_status(:success)
      end
      
      it 'returns JSON with all recipes' do
        get api_v1_recipes_path, headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response.size).to eq(3)
      end
      
      it 'includes recipe attributes in JSON' do
        get api_v1_recipes_path, headers: headers
        json_response = JSON.parse(response.body)
        
        recipe_titles = json_response.map { |r| r['title'] }
        expect(recipe_titles).to match_array(recipes.map(&:title))
      end
    end
    
    context 'when no recipes exist' do
      it 'returns an empty array' do
        get api_v1_recipes_path, headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response).to eq([])
      end
    end
  end
  
  describe 'GET /api/v1/recipes/:id' do
    let(:recipe) { create(:recipe, user: user) }
    let!(:comments) do
      create_list(:comment, 2, 
                  commentable: recipe, 
                  commentable_type: 'Recipe',
                  user: user)
    end
    
    context 'when recipe exists' do
      it 'returns a successful response' do
        get api_v1_recipe_path(recipe), headers: headers
        expect(response).to have_http_status(:success)
      end
      
      it 'returns JSON content type' do
        get api_v1_recipe_path(recipe), headers: headers
        expect(response.content_type).to match(%r{application/json})
      end
      
      it 'includes recipe title in JSON' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['title']).to eq(recipe.title)
      end
      
      it 'includes recipe instructions in JSON' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['instructions']).to eq(recipe.instructions)
      end
      
      it 'includes recipe prep_time in JSON' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['prep_time'].to_f).to eq(recipe.prep_time.to_f)
      end
      
      it 'includes recipe servings in JSON' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['servings'].to_f).to eq(recipe.servings.to_f)
      end
      
      it 'includes associated comments in JSON' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['comments']).to be_present
        expect(json_response['comments'].size).to eq(2)
      end
      
      it 'includes comment content in JSON' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        comment_contents = json_response['comments'].map { |c| c['content'] }
        expect(comment_contents).to match_array(comments.map(&:content))
      end
      
      it 'includes comment user information in JSON' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        first_comment = json_response['comments'].first
        expect(first_comment['user']).to be_present
        expect(first_comment['user']['email']).to eq(user.email)
      end
      
      it 'includes user information with id, name, and email' do
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        aggregate_failures do
          expect(json_response['user']).to be_present
          expect(json_response['user']['id']).to eq(user.id)
          expect(json_response['user']['name']).to eq(user.name)
          expect(json_response['user']['email']).to eq(user.email)
        end
      end
      
      it 'includes recipe ingredients in JSON' do
        ingredient = create(:ingredient)
        create(:recipe_ingredient, 
               recipe: recipe, 
               ingredient: ingredient,
               quantity: '2',
               unit: 'cups')
        
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['recipe_ingredients']).to be_present
        expect(json_response['recipe_ingredients'].size).to eq(1)
        expect(json_response['recipe_ingredients'].first['quantity'].to_f).to eq(2.0)
        expect(json_response['recipe_ingredients'].first['unit']).to eq('cups')
      end
      
      it 'includes tags in JSON' do
        tag = create(:tag)
        recipe.tags << tag
        
        get api_v1_recipe_path(recipe), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['tags']).to be_present
        expect(json_response['tags'].size).to eq(1)
      end
    end
    
    context 'when recipe does not exist' do
      it 'returns 404 status' do
        get api_v1_recipe_path(id: 99999), headers: headers
        expect(response).to have_http_status(:not_found)
      end
      
      it 'returns JSON error message' do
        get api_v1_recipe_path(id: 99999), headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['error']).to be_present
      end
    end
  end
  
  describe 'GET /api/v1/recipes/latest' do
    context 'when recipes exist' do
      let!(:old_recipe) { create(:recipe, created_at: 1.day.ago) }
      let!(:new_recipe) { create(:recipe, created_at: Time.current) }
      let(:json_response) { JSON.parse(response.body) }

      before { get latest_api_v1_recipes_path }

      it 'returns a 200 OK status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the most recently created recipe ID' do
        expect(json_response['id']).to eq(new_recipe.id)
      end

      it 'includes the associated user information' do
        expect(json_response['user']).to be_present
      end

      it 'includes user id, name, and email in latest recipe' do
        aggregate_failures do
          expect(json_response['user']['id']).to eq(new_recipe.user.id)
          expect(json_response['user']['name']).to eq(new_recipe.user.name)
          expect(json_response['user']['email']).to eq(new_recipe.user.email)
        end
      end

      it 'includes the recipe ingredients list' do
        expect(json_response).to have_key('recipe_ingredients')
      end

      it 'does not require an authorization header' do
        # This is implicitly tested by the 'before' block running without headers
        expect(response).to have_http_status(:success)
      end
    end

    context 'when no recipes exist' do
      before do
        Recipe.destroy_all
        get latest_api_v1_recipes_path
      end

      it 'returns a 404 Not Found status' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns the correct error message' do
        expect(JSON.parse(response.body)['message']).to eq("No recipes found")
      end
    end
  end

  describe 'GET /api/v1/recipes/my_recipes' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
    let(:other_token) { create(:doorkeeper_access_token, resource_owner_id: other_user.id) }
    let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
    let(:other_headers) { { "Authorization" => "Bearer #{other_token.token}", "Accept" => "application/json" } }

    context 'when user is authenticated' do
      context 'when user has recipes' do
        let!(:user_recipes) { create_list(:recipe, 3, user: user) }
        let!(:other_recipes) { create_list(:recipe, 2, user: other_user) }

        it 'returns only current user recipes' do
          get my_recipes_api_v1_recipes_path, headers: headers
          json_response = JSON.parse(response.body)

          aggregate_failures do
            expect(json_response.size).to eq(3)
            expect(json_response.map { |r| r['user_id'] }).to all(eq(user.id))
          end
        end

        it 'returns recipes in descending order by created_at' do
          get my_recipes_api_v1_recipes_path, headers: headers
          json_response = JSON.parse(response.body)

          recipe_ids = json_response.map { |r| r['id'] }
          expect(recipe_ids).to eq(user_recipes.reverse.map(&:id))
        end

        it 'includes user information with id, name, and email' do
          get my_recipes_api_v1_recipes_path, headers: headers
          json_response = JSON.parse(response.body)

          aggregate_failures do
            expect(json_response.first['user']['id']).to eq(user.id)
            expect(json_response.first['user']['name']).to eq(user.name)
            expect(json_response.first['user']['email']).to eq(user.email)
          end
        end

        
      end

      context 'when user has no recipes' do
        it 'returns an empty array' do
          get my_recipes_api_v1_recipes_path, headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response).to eq([])
        end
      end
    end

    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        get my_recipes_api_v1_recipes_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  
  describe 'POST /api/v1/recipes' do
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
            post api_v1_recipes_path, params: { recipe: valid_attributes }, headers: headers
          }.to change(Recipe, :count).by(1)
        end
        
        it 'returns 201 created status' do
          post api_v1_recipes_path, params: { recipe: valid_attributes }, headers: headers
          expect(response).to have_http_status(:created)
        end
        
        it 'returns the created recipe as JSON' do
          post api_v1_recipes_path, params: { recipe: valid_attributes }, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['title']).to eq('Chocolate Cake')
          expect(json_response['instructions']).to eq('Mix and bake')
          expect(json_response['prep_time'].to_f).to eq(30.0)
        end
        
        it 'includes user information with id, name, and email in created recipe' do
          post api_v1_recipes_path, params: { recipe: valid_attributes }, headers: headers
          json_response = JSON.parse(response.body)
          
          aggregate_failures do
            expect(json_response['user']).to be_present
            expect(json_response['user']['id']).to eq(user.id)
            expect(json_response['user']['name']).to eq(user.name)
            expect(json_response['user']['email']).to eq(user.email)
          end
        end
        
        it 'assigns the recipe to the current user' do
          post api_v1_recipes_path, params: { recipe: valid_attributes }, headers: headers
          expect(Recipe.last.user).to eq(user)
        end
      end
      
      context 'with invalid parameters' do
        it 'does not create a new recipe' do
          expect {
            post api_v1_recipes_path, params: { recipe: invalid_attributes }, headers: headers
          }.not_to change(Recipe, :count)
        end
        
        it 'returns 422 unprocessable entity status' do
          post api_v1_recipes_path, params: { recipe: invalid_attributes }, headers: headers
          expect(response).to have_http_status(:unprocessable_content)
        end
        
        it 'returns validation errors as JSON' do
          post api_v1_recipes_path, params: { recipe: invalid_attributes }, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['errors']).to be_present
        end
      end
    end
    
    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        post api_v1_recipes_path, params: { recipe: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe 'PATCH /api/v1/recipes/:id' do
    let(:recipe) { create(:recipe, user: user) }
    
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
          patch api_v1_recipe_path(recipe), params: { recipe: new_attributes }, headers: headers
          recipe.reload
          
          expect(recipe.title).to eq('Updated Recipe Title')
          expect(recipe.prep_time).to eq(45)
        end
        
        it 'returns 200 OK status' do
          patch api_v1_recipe_path(recipe), params: { recipe: new_attributes }, headers: headers
          expect(response).to have_http_status(:ok)
        end
        
        it 'returns the updated recipe as JSON' do
          patch api_v1_recipe_path(recipe), params: { recipe: new_attributes }, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['title']).to eq('Updated Recipe Title')
          expect(json_response['prep_time'].to_f).to eq(45.0)
        end
        
        it 'includes user information with id, name, and email in updated recipe' do
          patch api_v1_recipe_path(recipe), params: { recipe: new_attributes }, headers: headers
          json_response = JSON.parse(response.body)
          
          aggregate_failures do
            expect(json_response['user']).to be_present
            expect(json_response['user']['id']).to eq(user.id)
            expect(json_response['user']['name']).to eq(user.name)
            expect(json_response['user']['email']).to eq(user.email)
          end
        end
      end
      
      context 'with invalid parameters' do
        it 'does not update the recipe' do
          original_title = recipe.title
          patch api_v1_recipe_path(recipe), params: { recipe: invalid_attributes }, headers: headers
          recipe.reload
          
          expect(recipe.title).to eq(original_title)
        end
        
        it 'returns 422 unprocessable entity status' do
          patch api_v1_recipe_path(recipe), params: { recipe: invalid_attributes }, headers: headers
          expect(response).to have_http_status(:unprocessable_content)
        end
        
        it 'returns validation errors as JSON' do
          patch api_v1_recipe_path(recipe), params: { recipe: invalid_attributes }, headers: headers
          json_response = JSON.parse(response.body)
          
          expect(json_response['errors']).to be_present
        end
      end
    end
    
    context 'when user is not the recipe owner' do
      before { sign_in other_user }
      
      it 'returns 403 forbidden status' do
        patch api_v1_recipe_path(recipe), params: { recipe: new_attributes }, headers: other_headers
        expect(response).to have_http_status(:forbidden)
      end
      
      it 'does not update the recipe' do
        original_title = recipe.title
        patch api_v1_recipe_path(recipe), params: { recipe: new_attributes }, headers: other_headers
        recipe.reload
        
        expect(recipe.title).to eq(original_title)
      end
    end
    
    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        patch api_v1_recipe_path(recipe), params: { recipe: new_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe 'DELETE /api/v1/recipes/:id' do
    let(:recipe) { create(:recipe, user: user) }
    
    context 'when user is the recipe owner' do
      before { sign_in user }
      
      it 'destroys the requested recipe' do
        recipe_to_delete = create(:recipe, user: user)
        expect {
          delete api_v1_recipe_path(recipe_to_delete), headers: headers
        }.to change(Recipe, :count).by(-1)
      end
      
      it 'returns 200 ok status' do
        delete api_v1_recipe_path(recipe), headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
    
    context 'when user is not the recipe owner' do
      before { sign_in other_user }
      
      it 'returns 403 forbidden status' do
        delete api_v1_recipe_path(recipe), headers: other_headers
        expect(response).to have_http_status(:forbidden)
      end
      
      it 'does not destroy the recipe' do
        recipe
        expect {
          delete api_v1_recipe_path(recipe), headers: other_headers
        }.not_to change(Recipe, :count)
      end
    end
    
    context 'when user is not authenticated' do
      it 'returns 401 unauthorized status' do
        delete api_v1_recipe_path(recipe)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end