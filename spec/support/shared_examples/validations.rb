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

RSpec.shared_examples :integer_column do |attribute, min:, allow_nil: false, factory: nil, traits: []|
  subject { build(factory || described_class.model_name.param_key, *traits, attribute => value) }

  context "#{attribute}が#{min}のとき" do
    let(:value) { min }

    it { is_expected.to be_valid }
  end

  context "#{attribute}が#{min - 1}のとき" do
    let(:value) { min - 1 }

    it { is_expected.to be_invalid }
  end

  context "#{attribute}が小数のとき" do
    let(:value) { min + 0.5 }

    it { is_expected.to be_invalid }
  end

  context "#{attribute}がnilのとき" do
    let(:value) { nil }

    if allow_nil
      it { is_expected.to be_valid }
    else
      it { is_expected.to be_invalid }
    end
  end
end
