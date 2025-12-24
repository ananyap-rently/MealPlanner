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

  # Role validation (since role is a string, NOT integer)
  validates :role, inclusion: { in: %w[standard premium], allow_nil: true }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # Check if user is premium
  def premium?
    role == 'premium'
  end
  
  def standard?
    role == 'standard'
  end
end
