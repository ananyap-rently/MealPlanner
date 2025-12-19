class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  attr_accessor :new_ingredient_name
  before_validation :assign_ingredient_from_name

  private

  def assign_ingredient_from_name
    return if new_ingredient_name.blank?

    self.ingredient = Ingredient.find_or_create_by(
      name: new_ingredient_name.strip
    )
  end
end
