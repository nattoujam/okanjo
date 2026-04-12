class Member < ApplicationRecord
  belongs_to :group
  has_many :paid_payments, class_name: "Payment", foreign_key: :payer_member_id, dependent: :destroy

  validates :name, presence: true
end
