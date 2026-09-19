FactoryBot.define do
  factory :activity_log do
    association :group
    action { 'member.create' }
    association :subject, factory: :member
    after { { 'name' => 'テストメンバー' } }
  end
end
