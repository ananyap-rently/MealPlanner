require 'rails_helper'

RSpec.describe "Admin::Recipes", type: :request do
  let!(:admin_user) { create(:admin_user) }
  let!(:user) { create(:user) }
  let!(:ingredient) { create(:ingredient) }
  let!(:tag) { create(:tag) }

  before do
    sign_in admin_user
  end

  describe "GET /admin/recipes" do
    it "renders the index with related data" do
      recipe = create(
        :recipe,
        title: "Unique Recipe Title",
        user: user
      )

      get admin_recipes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unique Recipe Title")
      expect(response.body).to include(user.name)
    end
  end

#   describe "POST /admin/recipes" do
#     context "with valid nested attributes" do
#       let(:recipe_params) do
#         {
#           recipe: {
#             title: "New Pasta #{SecureRandom.hex(4)}",
#             user_id: user.id,
#             prep_time: 15,
#             servings: 2,
#             instructions: "Boil water, add pasta.",
#             tag_ids: [tag.id],
#             recipe_ingredients_attributes: {
#               "0" => {
#                 ingredient_id: ingredient.id,
#                 quantity: "100"
#               }
#             }
#           },
#           commit: "Create Recipe"
#         }
#       end

#       it "creates a recipe with ingredients and tags" do
#         expect {
#           post admin_recipes_path, params: recipe_params
#         }.to change(Recipe, :count).by(1)
#          .and change(RecipeIngredient, :count).by(1)

#         recipe = Recipe.last
#         expect(recipe.title).to include("New Pasta")
#         expect(recipe.tags).to include(tag)
#         expect(recipe.recipe_ingredients.first.quantity).to eq("100")
#         expect(recipe.recipe_ingredients.first.ingredient).to eq(ingredient)
#       end
#     end
#   end

  describe "PATCH /admin/recipes/:id" do
    let!(:recipe) { create(:recipe, user: user) }
    let!(:recipe_ingredient) do
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
    end

    it "allows destroying a nested ingredient" do
      patch admin_recipe_path(recipe), params: {
        recipe: {
          recipe_ingredients_attributes: {
            "0" => {
              id: recipe_ingredient.id,
              _destroy: "1"
            }
          }
        },
        commit: "Update Recipe"
      }

      expect(recipe.reload.recipe_ingredients.count).to eq(0)
    end
  end
end