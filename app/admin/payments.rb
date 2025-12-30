ActiveAdmin.register Payment do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :shopping_list_item_id, :payment_status
  includes shopping_list_item: :purchasable
   #
  # or
  #
  # permit_params do
  #   permitted = [:shopping_list_item_id, :payment_status]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :shopping_list_item_id
  filter :payment_status
  
  index do
    selectable_column
    id_column
    column "Shopping List Item" do |payment|
      if payment.shopping_list_item
        link_to "Item ##{payment.shopping_list_item_id}", admin_shopping_list_item_path(payment.shopping_list_item)
      else
        "No Item Linked"
      end
    end
    column :payment_status
    actions
  end

  form do |f|
    f.input :shopping_list_item_id
    f.input :payment_status
  
  f.actions
end
end
