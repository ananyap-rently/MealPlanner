# spec/requests/comments_spec.rb
require 'rails_helper'

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:recipe) { create(:recipe) }
  let(:meal_plan) { create(:meal_plan) }

  describe "POST /create" do
    context "when authenticated" do
      before { sign_in user }

      context "commenting on a Recipe" do
        let(:valid_params) { { comment: { content: "Delicious!" } } }

        it "creates a new comment for the recipe" do
          expect {
            # This triggers the recipe_id match in find_commentable
            post recipe_comments_path(recipe), params: valid_params
          }.to change(Comment, :count).by(1)
        end

        it "assigns the comment to the current user" do
          post recipe_comments_path(recipe), params: valid_params
          expect(Comment.last.user).to eq(user)
        end

        it "redirects to the recipe show page" do
          post recipe_comments_path(recipe), params: valid_params
          expect(response).to redirect_to(recipe_path(recipe))
        end
      end

      context "commenting on a Meal Plan" do
        let(:valid_params) { { comment: { content: "Well planned!" } } }

        it "creates a new comment for the meal plan" do
          expect {
            # This triggers the meal_plan_id match in find_commentable
            post meal_plan_comments_path(meal_plan), params: valid_params
          }.to change(Comment, :count).by(1)
          
          expect(Comment.last.commentable).to eq(meal_plan)
        end
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in page" do
        post recipe_comments_path(recipe), params: { comment: { content: "Nice" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:comment) { create(:comment, commentable: recipe, user: user) }

    context "when authenticated" do
      before { sign_in user }

      it "destroys the comment" do
        expect {
          delete recipe_comment_path(recipe, comment)
        }.to change(Comment, :count).by(-1)
      end

      it "redirects back to the commentable show page" do
        delete recipe_comment_path(recipe, comment)
        expect(response).to redirect_to(recipe_path(recipe))
        expect(flash[:notice]).to eq("Comment deleted successfully")
      end
    end

    context "when unauthenticated" do
      it "does not destroy the comment and redirects to login" do
        expect {
          delete recipe_comment_path(recipe, comment)
        }.not_to change(Comment, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end