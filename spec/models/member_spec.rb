require 'rails_helper'

RSpec.describe Member, type: :model do
  describe 'validations' do
    it_behaves_like :required_string_column, :name
  end

  describe 'associations' do
    context 'groupが存在しないとき' do
      subject { build(:member, group: nil) }

      it { is_expected.to be_invalid }
    end
  end
end
