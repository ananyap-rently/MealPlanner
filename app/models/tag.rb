class Tag < ApplicationRecord
    has_and_belongs_to_many :recipes
    validates :tag_name, presence: true,uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    ["id", "tag_name", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["recipes"]
  end

end
