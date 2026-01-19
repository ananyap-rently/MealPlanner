require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'Associations' do
    it { should have_and_belong_to_many(:recipes) }
  end

  describe 'Validations' do
    subject { build(:tag) } # Required for uniqueness validation matcher

    it { should validate_presence_of(:tag_name) }
    it { should validate_uniqueness_of(:tag_name) }

    it 'is valid with a unique name' do
      expect(build(:tag)).to be_valid
    end
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "tag_name", "created_at", "updated_at"]
      expect(Tag.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows the recipes association to be searchable' do
      expect(Tag.ransackable_associations).to match_array(["recipes"])
    end
  end
end