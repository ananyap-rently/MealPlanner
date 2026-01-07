ActiveAdmin.register Recipe do

 
  permit_params :title, :instructions, :prep_time, :servings, :user_id,
                tag_ids: [], 
                recipe_ingredients_attributes: [:id, :ingredient_id, :quantity, :_destroy]
  
  
  
  
  
  filter :user
  filter :title
  filter :prep_time
  filter :servings
  filter :created_at

  
  filter :ingredients_id, as: :select, collection: -> { Ingredient.all.map { |i| [i.name, i.id] } }, label: 'Ingredient'


  # This line tells Rails to fetch ingredients in just 1 or 2 queries total
  includes :user, :ingredients, :tags

  index do
    selectable_column
    id_column
    column :title
    column :user
    column "Prep (mins)", :prep_time
    column :servings
    column :ingredients do |recipe|
      recipe.ingredients.map(&:name).join(", ")
      link_to "View Quantities", admin_recipe_ingredients_path('q[recipe_id_eq]' => recipe.id)
    end
    column :tags do |recipe|
      recipe.tags.map(&:tag_name).join(", ")
    end
    actions
  end


  form do |f|
    f.semantic_errors # Shows errors at the top of the form

    f.inputs "Basic Information" do
      f.input :user, as: :select, collection: User.all.map { |u| [u.email, u.id] }
      f.input :title
      f.input :prep_time, label: "Preparation Time (minutes)"
      f.input :servings
      f.input :instructions, as: :text
    end

    f.inputs "Classification" do
      # This creates a multi-select box or checkboxes for Tags
      f.input :tags, as: :check_boxes, collection: Tag.all
    end

    #Adding ingredients directly inside the Recipe form
    f.inputs "Ingredients" do
      f.has_many :recipe_ingredients, heading: false, allow_destroy: true do |ri|
        ri.input :ingredient_id, as: :select, collection: Ingredient.all.map { |i| [i.name, i.id] }
        ri.input :quantity, placeholder: "e.g., 2 cups or 500g"
      end
    end

    f.actions
  end
end
