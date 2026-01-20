
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

# require 'rails_helper'

# RSpec.describe User, type: :model do
#   # 1. Factory & Basic Validations
#   it "has a valid factory" do
#     expect(build(:user)).to be_valid
#   end

#   describe "validations" do
#     it { is_expected.to validate_presence_of(:name) }
    
#     it "is invalid with a duplicate email" do
#       create(:user, email: "unique@example.com")
#       user = build(:user, email: "unique@example.com")
#       expect(user).not_to be_valid
#     end
    
#     it "validates the role inclusion" do
#       user = build(:user, role: "admin") # Not in ['standard', 'premium']
#       expect(user).not_to be_valid
#       expect(user.errors[:role]).to include("is not included in the list")
#     end
#   end

#   # 2. Association Tests
#   describe "associations" do
#     it { is_expected.to have_many(:access_tokens).dependent(:delete_all) }
#     it { is_expected.to have_many(:recipes).dependent(:destroy) }
#     it { is_expected.to have_many(:meal_plans).dependent(:destroy) }
#     it { is_expected.to have_many(:comments).dependent(:destroy) }
#     it { is_expected.to have_many(:shopping_list_items).dependent(:destroy) }
#     it { is_expected.to have_many(:payments).through(:shopping_list_items) }
#   end

#   # 3. Role Logic
#   describe "roles" do
#     let(:standard_user) { build(:user, role: "standard") }
#     let(:premium_user) { build(:user, role: "premium") }

#     context "#premium?" do
#       it "returns true if the user is premium" do
#         expect(premium_user.premium?).to be true
#       end
      
#       it "returns false if the user is standard" do
#         expect(standard_user.premium?).to be false
#       end
#     end

#     context "#standard?" do
#       it "returns true if the user is standard" do
#         expect(standard_user.standard?).to be true
#       end
      
#       it "returns false if the user is premium" do
#         expect(premium_user.standard?).to be false
#       end
#     end
#   end

#   # 4. Searchability (Ransack)
#   describe "ransackable methods" do
#     it "defines correct ransackable attributes" do
#       expected_attrs = ["id", "name", "email", "role", "bio", "created_at"]
#       expect(User.ransackable_attributes).to match_array(expected_attrs)
#     end
    
#     it "defines correct ransackable associations" do
#       expect(User.ransackable_associations).to eq([])
#     end
#   end

#   # ========================================
#   # NEW: STUBBING & MOCKING EXAMPLES
#   # ========================================

#   # 5. Stubbing - Controlling Method Return Values
#   describe "stubbing examples" do
#     let(:user) { create(:user) }

#     context "stubbing instance methods" do
#       it "stubs premium? to return true" do
#         # STUB: Force premium? to return true regardless of actual role
#         allow(user).to receive(:premium?).and_return(true)
        
#         expect(user.premium?).to be true
#         # This works even if user.role is 'standard'
#       end

#       it "stubs premium? to return false" do
#         allow(user).to receive(:premium?).and_return(false)
        
#         expect(user.premium?).to be false
#       end
#     end

#     context "stubbing associations" do
#       it "stubs recipes count without creating actual records" do
#         # STUB: Avoid hitting the database
#         allow(user).to receive_message_chain(:recipes, :count).and_return(5)
        
#         expect(user.recipes.count).to eq(5)
#         # No actual recipes created in DB
#       end
#     end

#     context "stubbing class methods" do
#       it "stubs User.find to return a specific user" do
#         fake_user = build(:user, name: 'Stubbed User')
#         allow(User).to receive(:find).with(999).and_return(fake_user)
        
#         result = User.find(999)
#         expect(result.name).to eq('Stubbed User')
#       end
#     end
#   end

#   # 6. Mocking - Verifying Method Calls

#   # 8. Testing Callbacks with Mocking
#   describe "callback testing with mocks" do
#     context "after_create callback" do
#       it "calls send_welcome_email after user creation" do
#         user = build(:user)
        
#         # EXPECT: Method should be called during save
#         expect(user).to receive(:send_welcome_email)
        
#         user.save
#       end
#     end

#     context "before_save callback" do
#       it "calls normalize_email before saving" do
#         user = build(:user, email: 'TEST@EXAMPLE.COM')
        
#         # SPY: Watch the method being called
#         allow(user).to receive(:normalize_email).and_call_original
        
#         user.save
        
#         expect(user).to have_received(:normalize_email)
#       end
#     end
#   end

 

  

    
#   end
# end