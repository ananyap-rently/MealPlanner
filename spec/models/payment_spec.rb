require 'rails_helper'

RSpec.describe Payment, type: :model do
  # Associations
  describe 'associations' do
    it { should belong_to(:shopping_list_item) }
    it { should have_one(:user).through(:shopping_list_item) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:payment_status) }
    it { should validate_inclusion_of(:payment_status).in_array(%w[pending completed]) }
  end

  # Scopes
  describe 'scopes' do
    let!(:pending_payment) { create(:payment, payment_status: 'pending') }
    let!(:completed_payment) { create(:payment, payment_status: 'completed') }
    let!(:deleted_payment) { create(:payment, deleted_at: Time.current) }

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
        Payment.unscoped do
          expect(Payment.active).to include(pending_payment)
          expect(Payment.active).to include(completed_payment)
          expect(Payment.active).not_to include(deleted_payment)
        end
      end
    end

    describe '.deleted' do
      it 'returns only deleted payments' do
        Payment.unscoped do
          expect(Payment.deleted).to include(deleted_payment)
          expect(Payment.deleted).not_to include(pending_payment)
          expect(Payment.deleted).not_to include(completed_payment)
        end
      end
    end

    describe 'default_scope' do
      it 'excludes soft-deleted records by default' do
        expect(Payment.all).not_to include(deleted_payment)
        expect(Payment.all).to include(pending_payment)
        expect(Payment.all).to include(completed_payment)
      end
    end
  end

  # Ransack configuration
  describe '.ransackable_attributes' do
    it 'returns the correct attributes' do
      expect(Payment.ransackable_attributes).to match_array(['id', 'shopping_list_item_id', 'payment_status'])
    end

    it 'accepts auth_object parameter' do
      expect(Payment.ransackable_attributes('some_auth')).to match_array(['id', 'shopping_list_item_id', 'payment_status'])
    end
  end

  describe '.ransackable_associations' do
    it 'returns the correct associations' do
      expect(Payment.ransackable_associations).to eq(['shopping_list_item'])
    end

    it 'accepts auth_object parameter' do
      expect(Payment.ransackable_associations('some_auth')).to eq(['shopping_list_item'])
    end
  end

  # Instance methods
  describe '#item_name' do
    context 'when shopping_list_item is nil' do
      let(:payment) { build(:payment, shopping_list_item: nil) }

      it 'returns "Unknown Item"' do
        expect(payment.item_name).to eq("Unknown Item")
      end
    end

    context 'when shopping_list_item.purchasable is nil' do
      let(:shopping_list_item) { build(:shopping_list_item, purchasable: nil) }
      let(:payment) { build(:payment, shopping_list_item: shopping_list_item) }

      it 'returns "Unknown Item"' do
        expect(payment.item_name).to eq("Unknown Item")
      end
    end

    context 'when purchasable_type is Item' do
      let(:item) { build(:item, item_name: 'Apple') }
      let(:shopping_list_item) { build(:shopping_list_item, purchasable: item, purchasable_type: 'Item') }
      let(:payment) { build(:payment, shopping_list_item: shopping_list_item) }

      it 'returns the item_name' do
        expect(payment.item_name).to eq('Apple')
      end
    end

    context 'when purchasable_type is Ingredient' do
      let(:ingredient) { build(:ingredient, name: 'Flour') }
      let(:shopping_list_item) { build(:shopping_list_item, purchasable: ingredient, purchasable_type: 'Ingredient') }
      let(:payment) { build(:payment, shopping_list_item: shopping_list_item) }

      it 'returns the ingredient name' do
        expect(payment.item_name).to eq('Flour')
      end
    end

    context 'when purchasable_type is unknown' do
      let(:shopping_list_item) do
        build(
          :shopping_list_item,
          purchasable: nil,
          purchasable_type: 'SomeOtherType'
        )
      end

      let(:payment) { build(:payment, shopping_list_item: shopping_list_item) }

      # it 'returns "Unknown Item"' do
      #   expect(payment.item_name).to eq("Unknown Item")
      # end
    end

  end

  describe '#soft_delete' do
    let(:payment) { create(:payment) }

    it 'sets deleted_at timestamp' do
      expect {
        payment.soft_delete
      }.to change { payment.reload.deleted_at }.from(nil)
    end

    it 'does not remove the record from database' do
      payment.soft_delete
      expect(Payment.unscoped.find_by(id: payment.id)).to be_present
    end
  end

  describe '#restore' do
    let(:payment) { create(:payment, deleted_at: Time.current) }

    it 'clears deleted_at timestamp' do
      Payment.unscoped do
        expect {
          payment.restore
        }.to change { payment.reload.deleted_at }.to(nil)
      end
    end
  end

  describe '#deleted?' do
    context 'when deleted_at is present' do
      let(:payment) { build(:payment, deleted_at: Time.current) }

      it 'returns true' do
        expect(payment.deleted?).to be true
      end
    end

    context 'when deleted_at is nil' do
      let(:payment) { build(:payment, deleted_at: nil) }

      it 'returns false' do
        expect(payment.deleted?).to be false
      end
    end
  end

  describe '#destroy' do
    let(:payment) { create(:payment) }

    it 'soft deletes the record instead of hard deleting' do
      payment.destroy
      expect(Payment.unscoped.find_by(id: payment.id)).to be_present
      expect(Payment.unscoped.find_by(id: payment.id).deleted_at).to be_present
    end

    it 'executes destroy logic via soft delete' do
      expect {
        payment.destroy
      }.to change { payment.reload.deleted_at }.from(nil)
    end

    it 'removes record from default scope' do
      payment.destroy
      expect(Payment.find_by(id: payment.id)).to be_nil
    end
  end

  describe '#really_destroy!' do
    let(:payment) { create(:payment) }

    it 'permanently removes the record from database' do
      payment_id = payment.id
      payment.really_destroy!
      expect(Payment.unscoped.find_by(id: payment_id)).to be_nil
    end

    it 'returns true when successfully deleted' do
      expect(payment.really_destroy!).to be true
    end

    it 'bypasses default scope' do
      payment_id = payment.id
      payment.really_destroy!
      Payment.unscoped do
        expect(Payment.find_by(id: payment_id)).to be_nil
      end
    end
  end

  # Callbacks
  describe 'callbacks' do
    describe 'after_update :mark_item_as_purchased' do
      let(:shopping_list_item) { create(:shopping_list_item, is_purchased: false) }
      let(:payment) { create(:payment, shopping_list_item: shopping_list_item, payment_status: 'pending') }

      context 'when payment_status changes to completed' do
        it 'marks the shopping_list_item as purchased' do
          expect {
            payment.update(payment_status: 'completed')
          }.to change { shopping_list_item.reload.is_purchased }.from(false).to(true)
        end
      end

      context 'when payment_status changes to pending' do
        let(:payment) { create(:payment, shopping_list_item: shopping_list_item, payment_status: 'completed') }
        
        before do
          shopping_list_item.update(is_purchased: true)
        end

        it 'marks the shopping_list_item as not purchased' do
          expect {
            payment.update(payment_status: 'pending')
          }.to change { shopping_list_item.reload.is_purchased }.from(true).to(false)
        end
      end

      context 'when payment_status does not change' do
        it 'does not update shopping_list_item' do
          expect(shopping_list_item).not_to receive(:update)
          payment.update(updated_at: Time.current)
        end
      end

      context 'when shopping_list_item is nil' do
        let(:payment_without_item) { create(:payment) }

        it 'does not raise an error' do
          allow(payment_without_item).to receive(:shopping_list_item).and_return(nil)
          expect {
            payment_without_item.update(payment_status: 'completed')
          }.not_to raise_error
        end
      end
    end
  end
end