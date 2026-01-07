ActiveAdmin.register Ingredient do

  
   permit_params :name
 
  filter :name
  filter :created_at
  index do
    selectable_column
    id_column
    column :name
    column :created_at
    actions #to show edit delete update actions
  end
  form do |f|
  f.inputs "Basic Information" do
    f.input :name, label: "Ingredient Name", hint: "Please use singular nouns (e.g., Tomato)"
  end
  f.actions # This is required to show the 'Submit' and 'Cancel' buttons
end
end
