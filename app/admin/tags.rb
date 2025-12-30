ActiveAdmin.register Tag do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :tag_name
   includes :recipes
  #
  # or
  #
  # permit_params do
  #   permitted = [:tag_name]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  index do
    selectable_column
    id_column
    column :tag_name
    column "Used in Recipes" do |tag|
     # We loop through each recipe associated with THIS tag
      tag.recipes.map { |r|
        link_to r.title, admin_recipe_path(r)
      }.join(", ").html_safe
    end
    actions
  end

  
filter :recipes, as: :select, collection: -> { Recipe.all.map { |r| [r.title, r.id] } }
  filter :tag_name

  
end
