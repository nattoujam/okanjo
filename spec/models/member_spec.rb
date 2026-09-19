require 'rails_helper'

RSpec.describe Member, type: :model do
  describe 'validations' do
    it_behaves_like :required_string_column, :name
  end

  describe '#audit_snapshot' do
    it '名前を返す' do
      expect(build(:member, name: '田中').audit_snapshot).to eq(name: '田中')
    end
  end

  describe 'associations' do
    context 'groupが存在しないとき' do
      subject { build(:member, group: nil) }

      it { is_expected.to be_invalid }
    end
  end
end
