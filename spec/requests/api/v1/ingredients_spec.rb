# spec/requests/api/v1/ingredients_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Ingredients", type: :request do
  let(:user) { create(:user) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  let!(:ingredient) { create(:ingredient, name: "Salt") }

  describe "GET /api/v1/ingredients" do
    it "allows public access and returns all ingredients ordered by name" do
      create(:ingredient, name: "Apple")
      
      # No headers passed to test skip_before_action
      get api_v1_ingredients_path
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first['name']).to eq("Apple") 
      expect(json.size).to eq(2)
    end

    it "returns empty array when no ingredients exist" do
      Ingredient.destroy_all
      
      get api_v1_ingredients_path
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe "GET /api/v1/ingredients/:id" do
    it "allows public access to show an ingredient" do
      get api_v1_ingredient_path(ingredient)
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['name']).to eq("Salt")
      expect(json['id']).to eq(ingredient.id)
    end

    it "returns 404 for non-existent ingredient (handled by BaseController)" do
      get api_v1_ingredient_path(99999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/ingredients" do
    let(:valid_params) { { ingredient: { name: "Pepper" } } }

    context "when authenticated" do
      it "creates a new ingredient with valid params" do
        expect {
          post api_v1_ingredients_path, params: valid_params, headers: headers
        }.to change(Ingredient, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq("Pepper")
        expect(Ingredient.last.name).to eq("Pepper")
      end

      it "returns created status even with empty name (no validation on Ingredient model)" do
        
        post api_v1_ingredients_path, 
             params: { ingredient: { name: "" } }, 
             headers: headers
        
        expect(response).to have_http_status(:created)
      end

      it "returns unprocessable content when ingredient save fails" do
        allow_any_instance_of(Ingredient).to receive(:save).and_return(false)
        allow_any_instance_of(Ingredient).to receive(:errors).and_return(double(full_messages: ["Name can't be blank"]))
        
        post api_v1_ingredients_path, params: valid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it "returns bad request when ingredient parameter is missing" do
        post api_v1_ingredients_path, params: {}, headers: headers
        
        expect(response).to have_http_status(:bad_request)
      end

      it "ignores unpermitted parameters" do
        post api_v1_ingredients_path, 
             params: { ingredient: { name: "Cumin", unpermitted_field: "value" } }, 
             headers: headers
        
        expect(response).to have_http_status(:created)
        expect(Ingredient.last.name).to eq("Cumin")
        
      end
    end

    context "when unauthenticated" do
      it "returns 401 unauthorized" do
        post api_v1_ingredients_path, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not create an ingredient when unauthenticated" do
        expect {
          post api_v1_ingredients_path, params: valid_params
        }.not_to change(Ingredient, :count)
      end
    end
  end
end