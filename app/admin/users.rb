ActiveAdmin.register User do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :name, :email, :role, :bio, :reset_password_sent_at, :remember_created_at
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :email, :role, :bio, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  

# 2. Define the Table View (Index)
  index do
    selectable_column
    id_column
    column :name
    column :email
    column :role
    column :created_at
    actions 
  end
# 3. Define the Sidebar Filters
  filter :email
  filter :name
  filter :role
  filter :created_at

# 4. Customize the Form (New/Edit)
  form do |f|
    f.inputs "User Details" do
      f.input :name
      f.input :email
      f.input :role, as: :select, collection: ["user", "manager"] # Example roles
      f.input :bio
      
      # Only show password fields if it's a new user 
      # OR if the admin specifically wants to reset it
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
# 5. Logic to handle blank passwords on update
  controller do
    def update
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end
end