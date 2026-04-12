FactoryBot.define do
  factory :payment do
    association :group
    association :payer, factory: :member
    description { 'ランチ代' }
    amount { 3000 }

    after(:build) do |payment|
      payment.payment_participants.build(member: payment.payer)
    end
  end
end
