class PagesController < ApplicationController
  skip_before_action :check_role_selection
  def home
  end
end
