FactoryBot.define do
  factory :member do
    association :group
    name { 'テストメンバー' }
  end
end
