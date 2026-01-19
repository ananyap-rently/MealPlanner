# spec/requests/admin/items_spec.rb
require 'rails_helper'

RSpec.describe "Admin::Items", type: :request do
  let(:admin_user) { AdminUser.first || FactoryBot.create(:admin_user) }
  let!(:item) { FactoryBot.create(:item, item_name: "Widget", quantity: 5) }

  before do
    # Assuming you use Devise for ActiveAdmin authentication
    sign_in admin_user
  end

  describe "Index Page" do
    it "renders the index page with correct columns" do
      get admin_items_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Widget")
      expect(response.body).to include("5")
    end

        it "allows filtering by item_name" do
  get admin_items_path, params: { q: { item_name_cont: "Widget" } }
  expect(response.body).to include("Widget")

  get admin_items_path, params: { q: { item_name_cont: "NonExistent" } }
  expect(response.body).not_to include("Widget")
end


  end

  describe "Form (New/Edit)" do
        it "renders the form with quantity min attribute" do
    get new_admin_item_path      # fixed
    expect(response.body).to include('min="0"')
    expect(response.body).to include('name="item[item_name]"')
    end

  end

  describe "Create Action" do
    context "with valid params" do
      it "creates a new item and redirects" do
        expect {
          post admin_items_path, params: { item: { item_name: "New Item", quantity: 20 } }
        }.to change(Item, :count).by(1)
        expect(response).to redirect_to(admin_item_path(Item.last))
      end
    end
  end

  describe "Update Action" do
    it "updates the item name" do
      put admin_item_path(item), params: { item: { item_name: "Updated Name" } }
      expect(item.reload.item_name).to eq("Updated Name")
      expect(response).to redirect_to(admin_item_path(item))
    end
  end

  describe "Delete Action" do
    it "removes the item" do
      expect {
        delete admin_item_path(item)
      }.to change(Item, :count).by(-1)
      expect(response).to redirect_to(admin_items_path)
    end
  end
end