FactoryBot.define do
  factory :payment do
    association :group
    association :payer, factory: :member
    description { 'ランチ代' }
    amount { 3000 }
  end
end
