# spec/factories/tags.rb
FactoryBot.define do
  factory :tag do
    tag_name { Faker::Food.unique.ethnic_category }
  end
end