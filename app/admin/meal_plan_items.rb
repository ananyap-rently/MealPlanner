ActiveAdmin.register MealPlanItem do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :meal_plan_id, :plannable_type, :plannable_id, :scheduled_date, :meal_slot
  #
  # or
  #
  # permit_params do
  #   permitted = [:meal_plan_id, :plannable_type, :plannable_id, :scheduled_date, :meal_slot]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :meal_plan_user_email, as: :string, label: "User Email"
  
  # Other safe filters
  filter :meal_plan
  filter :scheduled_date
  filter :meal_slot, as: :select, collection: ["Breakfast", "Lunch", "Dinner", "Snack"]
  filter :plannable_type

  index do
    selectable_column
    id_column
    column :meal_plan
    column "User" do |item|
      item.meal_plan.user.email
    end
    column :scheduled_date
    column :meal_slot
    column :plannable
    actions
  end
  form do |f|
    f.inputs "Meal Item Details" do
      f.input :meal_plan, as: :select, collection: MealPlan.all.map { |m| ["#{m.user.email} - #{m.category}", m.id] }
      f.input :scheduled_date, as: :datepicker
      f.input :meal_slot, as: :select, collection: ["Breakfast", "Lunch", "Dinner", "Snack"]
      
      # Polymorphic handling
      f.input :plannable_type, as: :select, collection: ["Recipe"] 
      f.input :plannable_id, as: :select, collection: Recipe.all.map { |r| [r.title, r.id] }, label: "Recipe"
    end
    f.actions
  end
end
