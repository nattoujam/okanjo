FactoryBot.define do
  factory :payment do
    association :group
    association :payer, factory: :member
    description { 'ランチ代' }
    amount { 3000 }

    transient do
      participants { [] }
    end

    after(:build) do |payment, evaluator|
      evaluator.participants.each do |member|
        payment.payment_participants.build(member: member)
      end
    end

    trait :with_participant do
      after(:build) do |payment|
        payment.payment_participants.build(member: payment.payer)
      end
    end
  end
end
