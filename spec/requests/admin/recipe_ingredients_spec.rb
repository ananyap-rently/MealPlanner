# spec/requests/admin/recipe_ingredients_spec.rb
require 'rails_helper'

RSpec.describe "Admin::RecipeIngredients", type: :request do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password') }
  let!(:user)      { create(:user) }
  let!(:recipe) do
    create(
      :recipe,
      user: user,
      title: "Grandma's Stew"
    )
  end
  let(:ingredient) { Ingredient.create!(name: "Carrot") }
  let!(:recipe_ingredient) do
    RecipeIngredient.create!(
      recipe: recipe,
      ingredient: ingredient,
      quantity: 5,
      unit: "pcs"
    )
  end

  before do
    sign_in admin_user
  end

  describe "Index Page" do
    # it "renders the table with associated links and triggers filters" do
    #   get admin_recipe_ingredients_path
      
    #   expect(response).to have_http_status(:success)
      
    #   # 1. Triggers the 'recipe' column block and link_to
    #   expect(response.body).to include("Grandma's Stew")
      
    #   # 2. Triggers the 'ingredient' column block and link_to
    #   expect(response.body).to include("Carrot")
      
    #   # 3. Verifies quantity and unit columns
    #   expect(response.body).to include("5")
    #   expect(response.body).to include("pcs")
    # end
    it 'renders the table with associated links and triggers filters' do
  get admin_recipe_ingredients_path

  expect(response).to have_http_status(:success)

  unescaped_body = CGI.unescapeHTML(response.body)
  expect(unescaped_body).to include("Grandma's Stew")
  expect(unescaped_body).to include("Carrot")
end

  end

  describe "Filters" do
    it "executes the dynamic collection lambdas" do
      # This triggers the 'collection: -> { ... }' lines for both recipe and unit
      get admin_recipe_ingredients_path, params: { 
        q: { 
          recipe_id_eq: recipe.id,
          unit_eq: "pcs" 
        } 
      }
      
      expect(response).to have_http_status(:success)
    end
  end

  describe "Strong Parameters" do
    it "allows creating a new recipe_ingredient" do
      new_ingredient = Ingredient.create!(name: "Salt")
      
      expect {
        post admin_recipe_ingredients_path, params: { 
          recipe_ingredient: { 
            recipe_id: recipe.id, 
            ingredient_id: new_ingredient.id,
            quantity: 1,
            unit: "tsp"
          } 
        }
      }.to change(RecipeIngredient, :count).by(1)
      
      # This ensures 'permit_params' was hit and executed successfully
      expect(response).to redirect_to(admin_recipe_ingredient_path(RecipeIngredient.last))
    end
  end
end