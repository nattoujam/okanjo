class Member < ApplicationRecord
  belongs_to :group
  has_many :payment_participants, dependent: :destroy
  has_many :participated_payments, through: :payment_participants, source: :payment
  has_many :paid_payments, class_name: "Payment", foreign_key: :payer_member_id, dependent: :destroy

  validates :name, presence: true
end
