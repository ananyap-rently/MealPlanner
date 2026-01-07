ActiveAdmin.register Item do

  
   permit_params :item_name, :quantity
 
  index do
    selectable_column
    id_column
    column :item_name
    column :quantity
    column :created_at
    actions
  end

  # Customize the Sidebar Filters
  filter :item_name
  filter :quantity
  filter :created_at

  # Customize the Edit/New Form
  form do |f|
    f.inputs "Item Details" do
      f.input :item_name
      f.input :quantity, min: 0
    end
    f.actions
  end
end
