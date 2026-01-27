# spec/requests/admin/ingredients_spec.rb
require 'rails_helper'

RSpec.describe "Admin::Ingredients", type: :request do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password') }
  let!(:ingredient) { Ingredient.create!(name: 'Salt') }

  before do
    sign_in admin_user
  end

  describe "Index Page" do
    it "renders the index table and filters" do
      get admin_ingredients_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Salt')
      # Triggers the index block and columns
      expect(response.body).to include('Name')
      expect(response.body).to include('Created At')
    end
  end

  describe "Form (New/Edit)" do
    it "renders the custom form fields and hints" do
      get new_admin_ingredient_path
      expect(response).to have_http_status(:success)
      # Execution of the 'form' block and the 'hint' line
      expect(response.body).to include('Please use singular nouns (e.g., Tomato)')
    end

    it "renders the edit page" do
      get edit_admin_ingredient_path(ingredient)
      expect(response).to have_http_status(:success)
    end
  end

  describe "Create/Update (Strong Params)" do
    it "allows creating a new ingredient" do
      expect {
        post admin_ingredients_path, params: { ingredient: { name: 'Pepper' } }
      }.to change(Ingredient, :count).by(1)
      # This triggers the permit_params line
      expect(response).to redirect_to(admin_ingredient_path(Ingredient.last))
    end

    it "updates an existing ingredient" do
      patch admin_ingredient_path(ingredient), params: { ingredient: { name: 'Sea Salt' } }
      expect(ingredient.reload.name).to eq('Sea Salt')
    end
  end

  describe "Filters" do
    it "executes the name filter" do
      get admin_ingredients_path, params: { q: { name_cont: 'Salt' } }
      expect(response).to have_http_status(:success)
    end
  end
end