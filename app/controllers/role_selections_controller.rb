# app/controllers/role_selections_controller.rb
class RoleSelectionsController < ApplicationController
  skip_before_action :check_role_selection
  before_action :authenticate_user!

  def new
    # Redirect if role already set
    if current_user.role.present?
      redirect_to root_path, notice: 'You have already selected your role.'
      return
    end
    
    # Store the page they were trying to access
    session[:return_to] ||= request.referer
  end

  def create
    if params[:role].blank?
      flash[:alert] = 'Please select a role.'
      redirect_to new_role_selection_path
      return
    end

    unless ['standard', 'premium'].include?(params[:role])
      flash[:alert] = 'Invalid role selected.'
      redirect_to new_role_selection_path
      return
    end

    if current_user.update(role: params[:role])
      # Get the page they were trying to access
      redirect_path = session.delete(:return_to) || root_path
      
      if current_user.premium?
        redirect_to redirect_path, notice: 'Successfully registered as a Premium user! You have full access to all features.'
      else
        redirect_to redirect_path, notice: 'Successfully registered as a Standard user! Welcome to our platform.'
      end
    else
      flash[:alert] = 'Failed to update role. Please try again.'
      redirect_to new_role_selection_path
    end
  end
end