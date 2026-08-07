FactoryBot.define do
  factory :payment_category do
    association :group
    sequence(:name) { |n| "テストカテゴリ#{n}" }
  end
end
