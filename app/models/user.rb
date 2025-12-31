class User < ApplicationRecord 
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :recipes, dependent: :destroy
  has_many :meal_plans, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :shopping_list_items,dependent: :destroy
  has_many :payments, through: :shopping_list_items

  # Add name validation
  validates :name, presence: true
  # Role validation (since role is a string, NOT integer)
  validates :role, inclusion: { in: %w[standard premium], allow_nil: true }
  
  # Check if user is premium
  def premium?
    role == 'premium'
  end
  
  def standard?
    role == 'standard'
  end

  # This tells Ransack which columns are safe to search/filter
  def self.ransackable_attributes(auth_object = nil)
    ["id", "name", "email", "role", "bio", "created_at"]
  end

  # This tells Ransack which associations (if any) are safe to search
  def self.ransackable_associations(auth_object = nil)
    [] # Add association names here if you want to search by things like 'posts'
  end
end
