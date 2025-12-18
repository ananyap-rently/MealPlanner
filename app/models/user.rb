class User < ApplicationRecord 
  has_many :recipes, dependent: :destroy
  has_many :meal_plans, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :shopping_list_items,dependent: :destroy
  
end
