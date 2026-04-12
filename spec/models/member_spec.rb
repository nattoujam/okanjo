require 'rails_helper'

RSpec.describe Member, type: :model do
  describe 'validations' do
    describe 'name' do
      subject { build(:member, name: name) }

      context 'バリデーション通過' do
        let(:name) { 'テスト名前' }

        it { is_expected.to be_valid }
      end

      context 'nameがnilのとき' do
        let(:name) { nil }

        it { is_expected.to be_invalid }
      end

      context 'nameがemptyのとき' do
        let(:name) { '' }

        it { is_expected.to be_invalid }
      end
    end
  end

  describe 'associations' do
    context 'groupが存在しないとき' do
      subject { build(:member, group: nil) }

      it { is_expected.to be_invalid }
    end
  end
end
