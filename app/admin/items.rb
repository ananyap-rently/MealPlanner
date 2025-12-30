ActiveAdmin.register Item do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :item_name, :quantity
  #
  # or
  #
  # permit_params do
  #   permitted = [:item_name, :quantity]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
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
