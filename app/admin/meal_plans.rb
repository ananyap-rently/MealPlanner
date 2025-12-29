ActiveAdmin.register MealPlan do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :category, :start_date, :user_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:category, :start_date, :user_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  filter :user
  filter :category, as: :select, collection: proc { MealPlan.pluck(:category).uniq }
  filter :start_date
  filter :created_at
  index do
    selectable_column
    id_column
    column :user
    column :category
    column :start_date
    actions
  end

  show do
    attributes_table do
      row :user
      row :category
      row :start_date
    end

    panel "Scheduled Meals (Items)" do
      table_for meal_plan.meal_plan_items do
        column :scheduled_date
        column :meal_slot
        column :plannable_type
        column "Item" do |item|
          item.plannable.respond_to?(:title) ? item.plannable.title : item.plannable_id
        end
      end
    end
  end
end
