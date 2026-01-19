# spec/requests/api/v1/comments_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Comments", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token.token}", "Accept" => "application/json" } }
  
  let(:recipe) { create(:recipe) }
  let(:meal_plan) { create(:meal_plan, user: user) }

  describe "GET /api/v1/:commentable_type/:id/comments" do
    let!(:comment) { create(:comment, commentable: recipe, user: user) }

    it "lists comments for a recipe" do
      get api_v1_recipe_comments_path(recipe), headers: headers
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first['content']).to eq(comment.content)
    end

    it "lists comments for a meal plan" do
      create(:comment, commentable: meal_plan, user: user)
      get api_v1_meal_plan_comments_path(meal_plan), headers: headers
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "POST /api/v1/:commentable_type/:id/comments" do
    let(:valid_params) { { comment: { content: "Delicious!" } } }

    context "when commenting on a recipe" do
      it "creates a comment associated with the recipe and current user" do
        expect {
          post api_v1_recipe_comments_path(recipe), params: valid_params, headers: headers
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(Comment.last.commentable).to eq(recipe)
        expect(Comment.last.user).to eq(user)
      end
    end

    context "with invalid params" do
      it "returns 422 unprocessable content (handled by BaseController via save!)" do
        post api_v1_recipe_comments_path(recipe), params: { comment: { content: "" } }, headers: headers
        
        # BaseController catches ActiveRecord::RecordInvalid from .save!
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/v1/comments/:id" do
    let!(:user_comment) { create(:comment, commentable: recipe, user: user) }
    let!(:other_comment) { create(:comment, commentable: recipe, user: other_user) }

    context "when the owner deletes the comment" do
      it "destroys the comment" do
        expect {
          delete api_v1_comment_path(user_comment), headers: headers
        }.to change(Comment, :count).by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when attempting to delete someone else's comment" do
      it "returns 404 not found (since find is scoped to current_user.comments)" do
        delete api_v1_comment_path(other_comment), headers: headers
        
        # Scoped search results in RecordNotFound if ID isn't in user's collection
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end