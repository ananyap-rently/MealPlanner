# spec/admin/tags_spec.rb
require 'rails_helper'

RSpec.describe 'Admin::Tags', type: :request do
  let(:admin_user) { AdminUser.create!(email: 'admin@example.com', password: 'password') }
    let!(:user)      { create(:user) }
  let!(:recipe)    { create(:recipe, user: user, title: 'Spaghetti Carbonara') }
  let!(:tag) { Tag.create!(tag_name: 'Italian') }

  before do
    # Link the tag to the recipe to test the 'Used in Recipes' column
    tag.recipes << recipe
    sign_in admin_user
  end

  describe 'Index page' do
    it 'renders the index page with custom columns' do
      get admin_tags_path
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Italian')
      # Verifies the link_to and map logic in the custom column
      expect(response.body).to include('Spaghetti Carbonara')
    end

    it 'filters by recipe' do
      get admin_tags_path, params: { q: { recipes_id_eq: recipe.id } }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'Permitted parameters' do
    it 'allows tag_name to be updated' do
      patch admin_tag_path(tag), params: { tag: { tag_name: 'New Name' } }
      expect(tag.reload.tag_name).to eq('New Name')
    end
  end
end