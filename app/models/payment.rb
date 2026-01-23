class Payment < ApplicationRecord
  belongs_to :shopping_list_item
  has_one :user, through: :shopping_list_item
  
  validates :payment_status, presence: true, inclusion: { in: %w[pending completed] }
  
  # Scopes
  scope :pending, -> { where(payment_status: 'pending') }
  scope :completed, -> { where(payment_status: 'completed') }
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  
  # Default scope to hide soft-deleted records
  default_scope { where(deleted_at: nil) }
  
  # Callbacks
  after_update :mark_item_as_purchased, if: :saved_change_to_payment_status?

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    ["id","shopping_list_item_id", "payment_status"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["shopping_list_item"]
  end

  # Instance methods
  def item_name
    return "Unknown Item" unless shopping_list_item&.purchasable

    case shopping_list_item.purchasable_type 
    when "Item"
      shopping_list_item.purchasable.item_name
    when "Ingredient"
      shopping_list_item.purchasable.name
    else
      "Unknown Item"
    end
  end

  def soft_delete
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end

  # Override destroy to use soft delete
  def destroy
    run_callbacks(:destroy) do
      soft_delete
    end
  end

  # Permanent deletion method - bypasses callbacks and actually removes from DB
  def really_destroy!
    # Use unscoped to bypass default_scope and delete without callbacks
    Payment.unscoped.where(id: self.id).delete_all > 0
  end

  private

  def mark_item_as_purchased
    return unless shopping_list_item

    if payment_status == "completed"
      shopping_list_item.update(is_purchased: true)
    elsif payment_status == "pending"
      shopping_list_item.update(is_purchased: false)
    end
  end
end
