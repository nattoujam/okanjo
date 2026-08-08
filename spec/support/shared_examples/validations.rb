RSpec.shared_examples :required_string_column do |attribute, factory: nil, traits: []|
  subject { build(factory || described_class.model_name.param_key, *traits, attribute => value) }

  context 'バリデーション通過' do
    let(:value) { 'テスト値' }

    it { is_expected.to be_valid }
  end

  context "#{attribute}がnilのとき" do
    let(:value) { nil }

    it { is_expected.to be_invalid }
  end

  context "#{attribute}がemptyのとき" do
    let(:value) { '' }

    it { is_expected.to be_invalid }
  end
end
