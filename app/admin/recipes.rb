ActiveAdmin.register Recipe do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  #permit_params :title, :instructions, :prep_time, :servings, :user_id
  permit_params :title, :instructions, :prep_time, :servings, :user_id,
                tag_ids: [], 
                recipe_ingredients_attributes: [:id, :ingredient_id, :quantity, :_destroy]
   #
  # or
  #
  # permit_params do
  #   permitted = [:title, :instructions, :prep_time, :servings, :user_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  
  # This prevents Active Admin from trying to create filters 
  # for complex associations that cause the Ransack error.
  config.filters = true
  # Explicitly define which filters appear in the sidebar
  filter :user
  filter :title
  filter :prep_time
  filter :servings
  filter :created_at

  # If you want to filter by ingredient, do it simply like this:
  # This avoids the "recipe_ingredients_ingredient_id" naming crash
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
    end
    # column :tags do |recipe|
    #   recipe.tags.map(&:name).join(", ")
    # end
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

    # This is the "Magic" part: Adding ingredients directly inside the Recipe form
    f.inputs "Ingredients" do
      f.has_many :recipe_ingredients, heading: false, allow_destroy: true do |ri|
        ri.input :ingredient_id, as: :select, collection: Ingredient.all.map { |i| [i.name, i.id] }
        ri.input :quantity, placeholder: "e.g., 2 cups or 500g"
      end
    end

    f.actions
  end
end
