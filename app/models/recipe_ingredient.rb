class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  attr_accessor :new_ingredient_name

  before_validation :create_ingredient_from_name
  validates :ingredient, presence: true
  validates :quantity, presence: {message: "can't be blank! "}
  validates :unit, presence: {message: "can't be blank" }
  private

  def create_ingredient_from_name
    if ingredient.blank? && new_ingredient_name.present?
      self.ingredient = Ingredient.find_or_create_by(name: new_ingredient_name.strip)
    end
  end
end
