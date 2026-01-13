require 'rails_helper'

RSpec.describe User, type: :model do
  
  # 1. Test that the Factory itself is valid
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  # 2. Validation Tests
  describe "validations" do
    it "is invalid without a name" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "is invalid with a duplicate email" do
      create(:user, email: "unique@example.com")
      user = build(:user, email: "unique@example.com")
      expect(user).not_to be_valid
    end

    it "is valid without a bio" do
      user = build(:user, bio: nil)
      expect(user).to be_valid
    end
  end

  # 3. Role/Enum Tests (Standard vs Premium)
  describe "role" do
    it "defaults to standard" do
      user = create(:user)
      expect(user.role).to eq("standard")
    end

    it "allows setting a premium role" do
      user = build(:user, role: "premium")
      expect(user.role).to eq("premium")
    end
  end

  # 4. Custom Method Tests
  # Let's say you have a method: user.premium?
  describe "#premium?" do
    it "returns true if the user is premium" do
      user = build(:user, role: "premium")
      expect(user.premium?).to be true
    end

    it "returns false if the user is standard" do
      user = build(:user, role: "standard")
      expect(user.premium?).to be false
    end
  end
end