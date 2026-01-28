# spec/requests/admin/meal_plans_spec.rb
require 'rails_helper'

RSpec.describe 'Admin MealPlans', type: :request do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password') }
  let(:user) { create(:user) }
  let!(:meal_plan) { create(:meal_plan, user: user, category: 'weekly') }
  
  before do
    sign_in admin_user
  end
  
  describe 'GET /admin/meal_plans' do
    it 'loads the index page' do
      get admin_meal_plans_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Meal Plans')
    end
  end
  
  describe 'GET /admin/meal_plans/:id' do
    it 'shows scheduled meals with title branch' do
      plannable = create(:recipe, title: 'Pasta')
      create(:meal_plan_item, meal_plan: meal_plan, plannable: plannable)
      
      get admin_meal_plan_path(meal_plan)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Pasta')
    end
    
    it 'shows scheduled meals without title branch' do
      plannable = create(:shopping_list_item)
      create(:meal_plan_item, meal_plan: meal_plan, plannable: plannable)
      
      get admin_meal_plan_path(meal_plan)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include(plannable.id.to_s)
    end
  end
end