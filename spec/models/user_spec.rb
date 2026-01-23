
require 'rails_helper'

RSpec.describe User, type: :model do
  
  # 1. Factory & Basic Validations
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    
    it "is invalid with a duplicate email" do
      create(:user, email: "unique@example.com")
      user = build(:user, email: "unique@example.com")
      expect(user).not_to be_valid
    end

    it "validates the role inclusion" do
      user = build(:user, role: "admin") # Not in ['standard', 'premium']
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("is not included in the list")
    end
  end

  # 2. Association Tests
  # Using 'shoulda-matchers' syntax here for cleanliness
  describe "associations" do
    it { is_expected.to have_many(:access_tokens).dependent(:delete_all) }
    it { is_expected.to have_many(:recipes).dependent(:destroy) }
    it { is_expected.to have_many(:meal_plans).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:shopping_list_items).dependent(:destroy) }
    it { is_expected.to have_many(:payments).through(:shopping_list_items) }
  end

  # 3. Role Logic
  describe "roles" do
    let(:standard_user) { build(:user, role: "standard") }
    let(:premium_user) { build(:user, role: "premium") }

    context "#premium?" do
      it "returns true if the user is premium" do
        expect(premium_user.premium?).to be true
      end

      it "returns false if the user is standard" do
        expect(standard_user.premium?).to be false
      end
    end

    context "#standard?" do
      it "returns true if the user is standard" do
        expect(standard_user.standard?).to be true
      end

      it "returns false if the user is premium" do
        expect(premium_user.standard?).to be false
      end
    end
  end

  # 4. Searchability (Ransack)
  describe "ransackable methods" do
    it "defines correct ransackable attributes" do
      expected_attrs = ["id", "name", "email", "role", "bio", "created_at"]
      expect(User.ransackable_attributes).to match_array(expected_attrs)
    end

    it "defines correct ransackable associations" do
      expect(User.ransackable_associations).to eq([])
    end
  end
end

