FactoryBot.define do
  factory :payment_participant do
    association :payment
    association :member
  end
end
