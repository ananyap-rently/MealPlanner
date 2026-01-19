require 'rails_helper'

RSpec.describe MealPlan, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should have_many(:meal_plan_items).dependent(:destroy) }
    it { should have_many(:shopping_list_items).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    
    it 'has many recipes through meal_plan_items' do
      # Testing the specific source/source_type logic
      expect(MealPlan.reflect_on_association(:recipes).options[:source]).to eq(:plannable)
      expect(MealPlan.reflect_on_association(:recipes).options[:source_type]).to eq('Recipe')
    end
  end

  describe 'Validations' do
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:start_date) }
  end

  describe 'Date Methods' do
    let(:start_date) { Date.parse('2024-01-01') } # A Monday
    let(:meal_plan) { build(:meal_plan, start_date: start_date) }

    describe '#end_date' do
      it 'returns a date 6 days after the start date' do
        expect(meal_plan.end_date).to eq(Date.parse('2024-01-07'))
      end
    end

    describe '#week_dates' do
      it 'returns an array of 7 dates' do
        expect(meal_plan.week_dates.size).to eq(7)
        expect(meal_plan.week_dates.first).to eq(start_date)
        expect(meal_plan.week_dates.last).to eq(start_date + 6.days)
      end
    end
  end

  describe 'Ransack Setup' do
    it 'allows specific attributes to be searchable' do
      expected_attrs = ["id", "category", "start_date", "user_id", "created_at"]
      expect(MealPlan.ransackable_attributes).to match_array(expected_attrs)
    end

    it 'allows specific associations to be searchable' do
      expected_assoc = ["user", "meal_plan_items", "shopping_list_items"]
      expect(MealPlan.ransackable_associations).to match_array(expected_assoc)
    end
  end
end