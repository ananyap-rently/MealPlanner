require 'rails_helper'

RSpec.describe Payment, type: :model do
  # Setup
  let(:user) { create(:user) }
  let(:item) { create(:item, item_name: "Test Item") }
  let(:ingredient) { create(:ingredient, name: "Test Ingredient") }
  let(:shopping_list_item_with_item) do
    create(:shopping_list_item, user: user, purchasable: item)
  end
  let(:shopping_list_item_with_ingredient) do
    create(:shopping_list_item, user: user, purchasable: ingredient)
  end
  let(:payment) { create(:payment, shopping_list_item: shopping_list_item_with_item) }

  # Associations
  describe 'associations' do
    it { should belong_to(:shopping_list_item) }
    it { should have_one(:user).through(:shopping_list_item) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:payment_status) }
    it { should validate_inclusion_of(:payment_status).in_array(%w[pending completed]) }
    
    it 'is valid with valid attributes' do
      expect(payment).to be_valid
    end
    
    it 'is invalid without payment_status' do
      payment.payment_status = nil
      expect(payment).not_to be_valid
    end
    
    it 'is invalid with an invalid payment_status' do
      expect {
        payment.payment_status = 'invalid_status'
        payment.valid?
      }.to change { payment.errors[:payment_status].any? }.from(false).to(true)
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:pending_payment) { create(:payment, payment_status: 'pending', shopping_list_item: shopping_list_item_with_item) }
    let!(:completed_payment) { create(:payment, payment_status: 'completed', shopping_list_item: create(:shopping_list_item, user: user, purchasable: item)) }
    let!(:deleted_payment) do
      payment = create(:payment, shopping_list_item: create(:shopping_list_item, user: user, purchasable: item))
      payment.update_column(:deleted_at, Time.current)
      payment
    end

    describe '.pending' do
      it 'returns only pending payments' do
        expect(Payment.pending).to include(pending_payment)
        expect(Payment.pending).not_to include(completed_payment)
      end
    end

    describe '.completed' do
      it 'returns only completed payments' do
        expect(Payment.completed).to include(completed_payment)
        expect(Payment.completed).not_to include(pending_payment)
      end
    end

    describe '.active' do
      it 'returns only non-deleted payments' do
        active_payments = Payment.unscoped.active
        expect(active_payments).to include(pending_payment, completed_payment)
        expect(active_payments).not_to include(deleted_payment)
      end
    end

    describe '.deleted' do
      it 'returns only deleted payments' do
        deleted_payments = Payment.unscoped.deleted
        expect(deleted_payments).to include(deleted_payment)
        expect(deleted_payments).not_to include(pending_payment, completed_payment)
      end
    end

    describe 'default_scope' do
      it 'excludes soft-deleted records by default' do
        expect(Payment.all).not_to include(deleted_payment)
        expect(Payment.all).to include(pending_payment, completed_payment)
      end
    end
  end

  # Callbacks
  describe 'callbacks' do
    describe 'after_update :mark_item_as_purchased' do
      context 'when payment_status changes to completed' do
        it 'marks the shopping list item as purchased' do
          payment.update(payment_status: 'pending')
          expect(payment.shopping_list_item.is_purchased).to eq(false)
          
          payment.update(payment_status: 'completed')
          expect(payment.shopping_list_item.reload.is_purchased).to eq(true)
        end
      end

      context 'when payment_status changes to pending' do
        it 'marks the shopping list item as not purchased' do
          payment.update(payment_status: 'completed')
          expect(payment.shopping_list_item.reload.is_purchased).to eq(true)
          
          payment.update(payment_status: 'pending')
          expect(payment.shopping_list_item.reload.is_purchased).to eq(false)
        end
      end

      context 'when payment_status does not change' do
        it 'does not trigger the callback' do
          payment.update(payment_status: 'pending')
          expect(payment.shopping_list_item).not_to receive(:update)
          
          payment.update(updated_at: Time.current)
        end
      end

      context 'when shopping_list_item is nil' do
        it 'does not raise an error' do
          payment.update(payment_status: 'pending')
          allow(payment).to receive(:shopping_list_item).and_return(nil)
          
          expect { payment.update(payment_status: 'completed') }.not_to raise_error
        end
      end
    end
  end

  # Ransack configuration
  describe 'ransack configuration' do
    describe '.ransackable_attributes' do
      it 'returns the correct attributes' do
        expect(Payment.ransackable_attributes).to match_array(["id", "shopping_list_item_id", "payment_status"])
      end

      it 'accepts an auth_object parameter' do
        expect(Payment.ransackable_attributes(:some_auth_object)).to match_array(["id", "shopping_list_item_id", "payment_status"])
      end
    end

    describe '.ransackable_associations' do
      it 'returns the correct associations' do
        expect(Payment.ransackable_associations).to eq(["shopping_list_item"])
      end

      it 'accepts an auth_object parameter' do
        expect(Payment.ransackable_associations(:some_auth_object)).to eq(["shopping_list_item"])
      end
    end
  end

  # Instance methods
  describe '#item_name' do
    context 'when shopping_list_item has an Item as purchasable' do
      it 'returns the item name' do
        payment = create(:payment, shopping_list_item: shopping_list_item_with_item)
        expect(payment.item_name).to eq("Test Item")
      end
    end

    context 'when shopping_list_item has an Ingredient as purchasable' do
      it 'returns the ingredient name' do
        payment = create(:payment, shopping_list_item: shopping_list_item_with_ingredient)
        expect(payment.item_name).to eq("Test Ingredient")
      end
    end

    context 'when shopping_list_item is nil' do
      it 'returns "Unknown Item"' do
        payment = build(:payment, shopping_list_item: nil)
        expect(payment.item_name).to eq("Unknown Item")
      end
    end

    context 'when shopping_list_item purchasable is nil' do
      it 'returns "Unknown Item"' do
        shopping_list_item = create(:shopping_list_item, user: user, purchasable: item)
        allow(shopping_list_item).to receive(:purchasable).and_return(nil)
        payment = create(:payment, shopping_list_item: shopping_list_item)
        
        expect(payment.item_name).to eq("Unknown Item")
      end
    end

    context 'when purchasable_type is unknown' do
      it 'returns "Unknown Item"' do
        shopping_list_item = create(:shopping_list_item, user: user, purchasable: item)
        allow(shopping_list_item).to receive(:purchasable_type).and_return("UnknownType")
        payment = create(:payment, shopping_list_item: shopping_list_item)
        
        expect(payment.item_name).to eq("Unknown Item")
      end
    end
  end

  describe '#soft_delete' do
    it 'sets deleted_at to current time' do
      expect(payment.deleted_at).to be_nil
      
      payment.soft_delete
      
      expect(payment.deleted_at).to be_present
      expect(payment.deleted_at).to be_within(1.second).of(Time.current)
    end

    it 'does not actually remove the record from the database' do
      payment.soft_delete
      
      expect(Payment.unscoped.find_by(id: payment.id)).to be_present
    end
  end

  describe '#restore' do
    it 'sets deleted_at to nil' do
      payment.soft_delete
      expect(payment.deleted_at).to be_present
      
      payment.restore
      
      expect(payment.reload.deleted_at).to be_nil
    end
  end

  describe '#deleted?' do
    it 'returns false when deleted_at is nil' do
      expect(payment.deleted?).to eq(false)
    end

    it 'returns true when deleted_at is present' do
      payment.soft_delete
      expect(payment.deleted?).to eq(true)
    end
  end

  describe '#destroy' do
    it 'soft deletes the record instead of destroying it' do
      payment_id = payment.id
      
      payment.destroy
      
      expect(Payment.unscoped.find_by(id: payment_id)).to be_present
      expect(Payment.find_by(id: payment_id)).to be_nil
      expect(payment.reload.deleted_at).to be_present
    end

    # it 'runs destroy callbacks' do
    #   expect(payment).to receive(:run_callbacks).with(:destroy).and_call_original
      
    #   payment.destroy
    # end
  end

  describe '#really_destroy!' do
    it 'permanently removes the record from the database' do
      payment_id = payment.id
      
      payment.really_destroy!
      
      expect(Payment.unscoped.find_by(id: payment_id)).to be_nil
    end

    it 'bypasses default_scope' do
      payment.soft_delete
      payment_id = payment.id
      
      payment.really_destroy!
      
      expect(Payment.unscoped.find_by(id: payment_id)).to be_nil
    end

    it 'returns true when deletion is successful' do
      expect(payment.really_destroy!).to be_truthy
    end

    it 'returns false when deletion fails' do
      payment.really_destroy!
      expect(payment.really_destroy!).to be_falsey
    end
  end
end