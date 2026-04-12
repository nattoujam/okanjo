require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'validations' do
    describe 'name' do
      subject { build(:group, name: name) }

      context 'バリデーション通過' do
        let(:name) { 'テスト名称' }

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

    describe 'token' do
      subject { build(:group, token: token) }

      context 'バリデーション通過' do
        let(:token) { 'token' }

        it { is_expected.to be_valid }
      end

      context 'tokenがemptyのとき' do
        let(:token) { '' }

        it { is_expected.to be_invalid }
      end

      context 'tokenが重複したとき' do
        let(:token) { 'duplicated_token' }

        before { create(:group, token: token) }

        it { is_expected.to be_invalid }
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_token' do
      context 'createのとき' do
        let(:group) { build(:group) }

        it do
          expect { group.valid? }.to change { group.token }.from(nil)
        end
      end

      context 'updateのとき' do
        let(:group) { create(:group) }

        it do
          group.name = '更新後の名前'
          expect { group.valid? }.not_to change { group.token }
        end
      end
    end
  end
end
