ActiveAdmin.register Comment, as: "UserComment" do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :user_id, :content, :commentable_type, :commentable_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:user_id, :content, :commentable_type, :commentable_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  menu label: "User Feedback"

  index do
    selectable_column
    id_column
    column :user
    column :content
    column "Target", :commentable
    column :created_at
    actions
  end


end
