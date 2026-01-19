require 'rails_helper'

RSpec.describe "Summaries", type: :request do
  # Removed the explicit 'text/html' headers as they often trigger 406 
  # errors if the controller/route is not perfectly aligned.
  
  let(:premium_user) do
    create(:user, role: 'premium', email: "premium#{# Unique email to avoid validation errors
      SecureRandom.hex(4)}@test.com")
  end

  before do
    recipe = create(:recipe, user: premium_user)

    meal_plan = create(
      :meal_plan,
      user: premium_user,
      start_date: Date.today
    )

    create(
      :meal_plan_item,
      meal_plan: meal_plan,
      plannable: recipe,
      scheduled_date: Date.today,
      meal_slot: "lunch"
    )

    ingredient = create(:ingredient)

    create(
      :recipe_ingredient,
      recipe: recipe,
      ingredient: ingredient
    )

    create(
      :shopping_list_item,
      user: premium_user,
      purchasable: recipe,
      is_purchased: true
    )
  end

  describe "Access Control" do
    it "redirects unauthenticated users to root" do
      # get summaries_path automatically defaults to the correct format
      get summaries_path

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "Premium User Actions" do
    before { sign_in premium_user }

    it "GET /summaries returns success" do
      get summaries_path
      expect(response).to have_http_status(:success)
    end

    it "GET /summaries/recipes returns success" do
      get recipes_summaries_path
      expect(response).to have_http_status(:success)
    end

    it "GET /summaries/meal_plans returns success" do
      get meal_plans_summaries_path
      expect(response).to have_http_status(:success)
    end

    it "GET /summaries/shopping returns success" do
      get shopping_summaries_path
      expect(response).to have_http_status(:success)
    end

    it "handles shopping summary with zero items" do
      premium_user.shopping_list_items.destroy_all

      get shopping_summaries_path
      expect(response).to have_http_status(:success)
    end
  end
end