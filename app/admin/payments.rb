ActiveAdmin.register Payment do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :shopping_list_item_id, :payment_status
  includes shopping_list_item: :purchasable
  scope :all, default: true
  scope :pending
  scope :completed
   #
  # or
  #
  # permit_params do
  #   permitted = [:shopping_list_item_id, :payment_status]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :shopping_list_item_id
 filter :payment_status, as: :select, collection: ["pending", "completed"]
  
 # 1. Batch Action to mark as Completed
  batch_action :mark_as_completed, confirm: "Mark selected payments as Completed?" do |ids|
    Payment.where(id: ids).update_all(payment_status: "Completed")
    redirect_to collection_path, notice: "Selected payments marked as Completed."
  end

  # 2. Batch Action to mark as Pending
  batch_action :mark_as_pending, confirm: "Mark selected payments as Pending?" do |ids|
    Payment.where(id: ids).update_all(payment_status: "Pending")
    redirect_to collection_path, notice: "Selected payments marked as Pending."
  end

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
    f.input :payment_status, as: :select, collection: ["Pending", "Completed"]
  
  f.actions
end
end
