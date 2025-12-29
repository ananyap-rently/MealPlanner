class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  validates :content, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["content", "user_id", "commentable_id", "commentable_type", "created_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "commentable"]
  end


end
