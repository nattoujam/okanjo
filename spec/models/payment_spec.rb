require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'validations' do
    it_behaves_like :required_string_column, :description, traits: [ :with_participant ]
    it_behaves_like :integer_column, :amount, min: 1, traits: [ :with_participant ]
    it_behaves_like :integer_column, :personal_amount, min: 0, allow_nil: true, traits: [ :with_participant ]

    describe '#personal_amount_must_be_less_than_amount' do
      subject { build(:payment, :with_participant, amount: 1000, personal_amount: personal_amount) }

      context 'personal_amountがamountと同額のとき' do
        let(:personal_amount) { 1000 }

        it { is_expected.to be_invalid }
      end

      context 'personal_amountがamountを超えるとき' do
        let(:personal_amount) { 1001 }

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

  describe 'callbacks' do
    describe 'personal_amountの既定値' do
      subject { build(:payment, :with_participant, personal_amount: nil) }

      it '0として扱われる' do
        subject.valid?
        expect(subject.personal_amount).to eq(0)
      end
    end
  end

  describe '#split_amount' do
    subject { build(:payment, :with_participant, amount: 1000, personal_amount: 300) }

    it '自分用の金額を除いた精算対象額を返す' do
      expect(subject.split_amount).to eq(700)
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
