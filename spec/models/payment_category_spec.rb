require 'rails_helper'

RSpec.describe PaymentCategory, type: :model do
  describe 'validations' do
    it_behaves_like :required_string_column, :name

    describe 'nameの一意性' do
      let(:group) { create(:group) }

      subject { build(:payment_category, group: group, name: name) }

      context '同じ割り勘グループ内でnameが重複したとき' do
        let(:name) { '1日目' }

        before { create(:payment_category, group: group, name: name) }

        it { is_expected.to be_invalid }
      end

      context '別の割り勘グループでnameが重複したとき' do
        let(:name) { '1日目' }

        before { create(:payment_category, group: create(:group), name: name) }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'callbacks' do
    describe '#assign_sequence' do
      let(:group) { create(:group) }

      context 'createのとき' do
        it '割り勘グループ内で作成順に採番する' do
          first  = create(:payment_category, group: group)
          second = create(:payment_category, group: group)

          expect(first.sequence).to eq(1)
          expect(second.sequence).to eq(2)
        end

        it '割り勘グループごとに独立して採番する' do
          create(:payment_category, group: group)
          other = create(:payment_category, group: create(:group))

          expect(other.sequence).to eq(1)
        end
      end

      context 'updateのとき' do
        let(:category) { create(:payment_category, group: group) }

        it 'sequenceを変更しない' do
          expect { category.update!(name: '初日') }.not_to change { category.sequence }
        end
      end
    end
  end

  describe 'sequenceの一意性制約' do
    let(:group) { create(:group) }
    let!(:day1) { create(:payment_category, group: group) }
    let!(:day2) { create(:payment_category, group: group) }

    it '同じ割り勘グループ内での重複を許さない' do
      expect { day2.update_column(:sequence, day1.sequence) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it '別の割り勘グループとの重複は許す' do
      other = create(:payment_category, group: create(:group))

      expect(other.sequence).to eq(day1.sequence)
    end
  end

  describe '#swap_sequence_with!' do
    let(:group) { create(:group) }
    let!(:day1) { create(:payment_category, group: group, name: '1日目') }
    let!(:day2) { create(:payment_category, group: group, name: '2日目') }

    it 'sequenceを入れ替える' do
      day1.swap_sequence_with!(day2)

      expect(day1.reload.sequence).to eq(2)
      expect(day2.reload.sequence).to eq(1)
    end

    it '並び順が入れ替わる' do
      expect { day1.swap_sequence_with!(day2) }
        .to change { group.payment_categories.reload.to_a }.from([ day1, day2 ]).to([ day2, day1 ])
    end

    it '隣り合わないカテゴリ同士でも入れ替えられる' do
      day3 = create(:payment_category, group: group, name: '3日目')

      day1.swap_sequence_with!(day3)

      expect(group.payment_categories.reload.to_a).to eq([ day3, day2, day1 ])
    end
  end

  describe '#destroy' do
    let(:group) { create(:group) }
    let(:member) { create(:member, group: group) }
    let(:category) { create(:payment_category, group: group) }
    let!(:payment) { create(:payment, :with_participant, group: group, payer: member, category: category) }

    it '紐づく立替払いは削除せずカテゴリを外す' do
      expect { category.destroy }.not_to change(Payment, :count)
      expect(payment.reload.payment_category_id).to be_nil
    end
  end
end
