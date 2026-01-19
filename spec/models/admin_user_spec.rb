require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  describe 'Devise Validations' do
    it 'is valid with valid attributes' do
      expect(build(:admin_user)).to be_valid
    end

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "email", "created_at", "updated_at"]
      expect(AdminUser.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'does not allow searching by password_hash or other sensitive fields' do
      expect(AdminUser.ransackable_attributes).not_to include("encrypted_password")
    end
  end
end