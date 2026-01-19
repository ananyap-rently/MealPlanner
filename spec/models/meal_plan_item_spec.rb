require 'rails_helper'

RSpec.describe MealPlanItem, type: :model do
  describe 'Associations' do
    it { should belong_to(:meal_plan) }
    it { should belong_to(:plannable) }
    it { should have_one(:user).through(:meal_plan) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:scheduled_date) }
    it { should validate_presence_of(:meal_slot) }
  end

  describe 'Enums' do
    it { should define_enum_for(:meal_slot).with_values(breakfast: 0, lunch: 1, dinner: 2, snack: 3) }
  end

  describe '#plannable_name' do
    context 'when plannable is a Recipe' do
      it 'returns the recipe title' do
        recipe = create(:recipe, title: 'Taco Tuesday')
        meal_plan_item = build(:meal_plan_item, plannable: recipe)
        expect(meal_plan_item.plannable_name).to eq('Taco Tuesday')
      end
    end

    context 'when plannable is an Item' do
      it 'returns the item_name' do
        item = create(:item, item_name: 'Protein Shake')
        meal_plan_item = build(:meal_plan_item, plannable: item)
        expect(meal_plan_item.plannable_name).to eq('Protein Shake')
      end
    end

    context 'when plannable is nil' do
      it 'returns Unknown' do
        meal_plan_item = build(:meal_plan_item, plannable: nil)
        expect(meal_plan_item.plannable_name).to eq('Unknown')
      end
    end
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "meal_slot", "scheduled_date", "plannable_type", "plannable_id"]
      expect(MealPlanItem.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows specific associations to be searchable' do
      expect(MealPlanItem.ransackable_associations).to match_array(["meal_plan", "plannable"])
    end
  end
end