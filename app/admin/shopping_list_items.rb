ActiveAdmin.register ShoppingListItem do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :user_id, :purchasable_type, :purchasable_id, :quantity, :is_purchased, :meal_plan_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:user_id, :purchasable_type, :purchasable_id, :quantity, :is_purchased, :meal_plan_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :user
  filter :purchasable_type, as: :select, collection: ["Item", "Ingredient"]
  filter :is_purchased
  filter :meal_plan
  filter :created_at
  index do
    selectable_column
    id_column
    column :user
    column "Source" do |sli|
      if sli.meal_plan_id.present?
         link_to "Meal Plan ##{sli.meal_plan.id}",
                admin_meal_plan_path(sli.meal_plan)
      else
        status_tag "Manual Entry", class: "warning"
      end
    end
    column "Purchasable" do |sli|
      sli.purchasable.try(:item_name) || sli.purchasable.try(:name) || "Deleted record"
    end
    column :quantity
    column :is_purchased
    actions
  end

  # 3. Form: Allow manual selection or optional Meal Plan assignment
  form do |f|
    f.inputs "Shopping List Item Details" do
      f.input :user

      f.input :meal_plan,
              hint: "Select a Meal Plan only if this item was generated from one"

      f.input :purchasable_type,
              as: :select,
              collection: ["Item", "Ingredient"],
              prompt: "Select Type"

      f.input :purchasable_id,
              as: :select,
              collection: (
                Item.all.map { |i| ["Item: #{i.item_name}", i.id] } +
                Ingredient.all.map { |ing| ["Ingredient: #{ing.name}", ing.id] }
              ),
              label: "Item / Ingredient"

      f.input :quantity
      f.input :is_purchased
    end
    f.actions
  end
end
