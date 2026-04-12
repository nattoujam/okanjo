require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'validations' do
    describe 'description' do
      subject { build(:payment, description: description) }

      context 'バリデーション通過' do
        let(:description) { 'ランチ代' }

        it { is_expected.to be_valid }
      end

      context 'descriptionがnilのとき' do
        let(:description) { nil }

        it { is_expected.to be_invalid }
      end

      context 'descriptionがemptyのとき' do
        let(:description) { '' }

        it { is_expected.to be_invalid }
      end
    end

    describe 'amount' do
      subject { build(:payment, amount: amount) }

      context 'バリデーション通過' do
        let(:amount) { 1000 }

        it { is_expected.to be_valid }
      end

      context 'amountがnilのとき' do
        let(:amount) { nil }

        it { is_expected.to be_invalid }
      end

      context 'amountが0のとき' do
        let(:amount) { 0 }

        it { is_expected.to be_invalid }
      end

      context 'amountが小数のとき' do
        let(:amount) { 0.1 }

        it { is_expected.to be_invalid }
      end

      context 'amountが負のとき' do
        let(:amount) { -1 }

        it { is_expected.to be_invalid }
      end
    end

    describe '#participants_must_exist' do
      context 'payment_participantsが空のとき' do
        subject do
          payment = build(:payment)
          payment.payment_participants.clear
          payment
        end

        it { is_expected.to be_invalid }
      end

      context 'payment_participantsが存在するとき' do
        subject { build(:payment, participants: [ create(:member) ]) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'associations' do
    context 'groupが存在しないとき' do
      subject { build(:payment, group: nil) }

      it { is_expected.to be_invalid }
    end

    context 'payerが存在しないとき' do
      subject { build(:payment, payer: nil) }

      it { is_expected.to be_invalid }
    end
  end
end
