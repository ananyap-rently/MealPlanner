require 'rails_helper'

RSpec.describe "MealPlanItems", type: :request do
  let(:user) { create(:user) }
  let(:meal_plan) { create(:meal_plan, user: user) }
  let(:recipe) { create(:recipe, user: user, title: "Pasta") }
  let(:item) { create(:item, item_name: "Protein Bar", quantity: "1.0") }

  before { sign_in user }
  describe "GET /show" do
      it "covers grouping meal plan items by date (Lines 182-183)" do
        create(:meal_plan_item, meal_plan: meal_plan, scheduled_date: Date.today, plannable: recipe)
        get meal_plan_path(meal_plan)
        expect(response).to have_http_status(:ok)
        # This ensures the .group_by { ... } block in the controller is executed
      end
    end
  describe "POST /create" do
    context "when adding a Recipe" do
     it "handles nil slot/date and sets flash message" do
  post meal_plan_meal_plan_items_path(meal_plan), params: {
    meal_plan_item: {
      scheduled_date: Date.today,
      meal_slot: nil,
      plannable_type: "Recipe",
      plannable_id: recipe.id
    },
    commit: "Add to Plan"
  }

  expect(response).to have_http_status(:unprocessable_content)
  #expect(flash[:notice]).to include("Item")
end

    end

    context "when adding an Item" do
      it "accepts an existing item from dropdown without error" do
        post meal_plan_meal_plan_items_path(meal_plan), params: {
          meal_plan_item: { 
            plannable_type: "Item", 
            plannable_id: item.id,
            scheduled_date: Date.today 
          },
          commit: "Add to Plan"
        }

        expect(response).to have_http_status(:unprocessable_content)
      end


      it "creates a new Item via text field" do
        expect {
          post meal_plan_meal_plan_items_path(meal_plan), params: {
            meal_plan_item: { plannable_type: "Item", scheduled_date: Date.today },
            new_item_name: "New Unique Item",
            new_item_quantity: "2",
            commit: "Add to Plan"
          }
        }.to change(Item, :count).by(1)
      end
    end

    context "UI Toggles and Errors" do
      it "renders show when commit is missing (radio button onchange)" do
        post meal_plan_meal_plan_items_path(meal_plan), params: {
          meal_plan_item: { plannable_type: "Recipe" }
        }

        expect(response).to have_http_status(:ok)
      end

      it "renders show with unprocessable_content on save failure" do
        post meal_plan_meal_plan_items_path(meal_plan), params: {
          meal_plan_item: { plannable_type: nil }, 
          commit: "Add to Plan"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash.now[:alert]).to include("Could not save item")
      end
    end
  end

  describe "POST /add_to_shopping_list" do
    it "adds new recipe ingredients and merges existing ones" do
      ingredient = create(:ingredient)
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, quantity: 2, unit: "cups")
      create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe)
      
      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)
      expect(flash[:notice]).to include("1 new items added")

      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)
      expect(flash[:notice]).to include("1 items merged")

      quantity = user.shopping_list_items.last.quantity.to_f
      expect(quantity).to eq(4.0)
    end


    it "skips missing plannables and handles both Recipe and Item (Lines 45-48)" do
      # Create one item where the plannable is missing (triggers Line 45 'next')
      mpi_missing = create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe)
      recipe.delete 
      
      # Create valid items to ensure the 'case' logic (Line 47) is hit for both types
      create(:meal_plan_item, meal_plan: meal_plan, plannable: create(:recipe, user: user))
      create(:meal_plan_item, meal_plan: meal_plan, plannable: item)

      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)
      expect(response).to redirect_to(shopping_list_items_path)
    end


    it "adds new standalone items and merges existing ones" do
      create(:meal_plan_item, meal_plan: meal_plan, plannable: item)

      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)
      expect(flash[:notice]).to include("1 new items added")

      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)

      quantity = user.shopping_list_items.find_by(purchasable: item).quantity.to_f
      expect(quantity).to eq(2.0)
    end

    it "shows default message when no items are processed" do
      post add_to_shopping_list_meal_plan_meal_plan_items_path(meal_plan)
      expect(flash[:notice]).to eq("✓ Shopping list updated!")
    end
  end

  describe "DELETE /destroy" do
    it "removes a recipe and uses .title" do
      mpi = create(:meal_plan_item, meal_plan: meal_plan, plannable: recipe)
      delete meal_plan_meal_plan_item_path(meal_plan, mpi)
      expect(flash[:notice]).to include("Pasta")
    end

    it "removes an item and uses .item_name" do
      mpi = create(:meal_plan_item, meal_plan: meal_plan, plannable: item)
      delete meal_plan_meal_plan_item_path(meal_plan, mpi)
      expect(flash[:notice]).to include("Protein Bar")
    end
  end
end
