ActiveAdmin.register RecipeIngredient do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :quantity, :unit, :recipe_id, :ingredient_id
  includes :recipe, :ingredient
  #
  # or
  #
  # permit_params do
  #   permitted = [:quantity, :unit, :recipe_id, :ingredient_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  index do
    selectable_column
    id_column
    # Links to the actual Recipe admin page
    column :recipe do |ri|
      link_to ri.recipe.title, admin_recipe_path(ri.recipe)
    end
    # Links to the Ingredient admin page
    column :ingredient do |ri|
      link_to ri.ingredient.name, admin_ingredient_path(ri.ingredient)
    end
    column :quantity
    column :unit
    actions
  end

  # Filters to help you find ingredients by recipe or unit
  filter :recipe, as: :select, collection: -> { Recipe.all.map { |r| [r.title, r.id] } }
  filter :ingredient
  filter :quantity
  filter :unit, as: :select, collection: -> { RecipeIngredient.pluck(:unit).uniq }
end
