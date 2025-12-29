class Recipe < ApplicationRecord
  belongs_to :user
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_and_belongs_to_many :tags
  has_many :meal_plan_items, as: :plannable
  has_many :comments, as: :commentable, dependent: :destroy
  #helps to save ingredients through recipe form
  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true

  #handle new tag input from form
  attr_accessor :new_tag_name
  validates :title, presence: true
  after_save :create_tag_from_name

  def self.ransackable_attributes(auth_object = nil)
    ["id", "title", "prep_time", "servings", "user_id", "created_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "ingredients", "tags"]
  end

  private

  def create_tag_from_name
    return if new_tag_name.blank?

    tag = Tag.find_or_create_by(tag_name: new_tag_name.strip)
    self.tags << tag unless self.tags.include?(tag)
  end

end
