require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:commentable) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:content) }
  end

  describe 'Polymorphic Behavior' do
    it 'is valid when associated with a Recipe' do
      comment = build(:comment, :for_recipe)
      expect(comment).to be_valid
      expect(comment.commentable_type).to eq('Recipe')
    end

    it 'is valid when associated with an Ingredient' do
      comment = build(:comment, :for_ingredient)
      expect(comment).to be_valid
      expect(comment.commentable_type).to eq('Ingredient')
    end
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["content", "user_id", "commentable_id", "commentable_type", "created_at"]
      expect(Comment.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows specific associations to be searchable' do
      expect(Comment.ransackable_associations).to match_array(["user", "commentable"])
    end
  end
end