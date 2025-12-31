class Ingredient < ApplicationRecord
    has_many :recipe_ingredients, dependent: :destroy
    has_many :recipes, through: :recipe_ingredients
    has_many :shopping_list_items, as: :purchasable
  def self.ransackable_attributes(auth_object = nil)
    ["id", "name", "created_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["recipe_ingredients", "recipes"]
  end


end
