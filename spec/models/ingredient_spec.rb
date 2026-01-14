RSpec.describe Ingredient, type: :model do
  it "is invalid without a name" do
    ingredient = Ingredient.new(name: nil)
    expect(ingredient).to_not be_valid
  end
end