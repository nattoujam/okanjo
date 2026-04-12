class Payment < ApplicationRecord
  belongs_to :group
  belongs_to :payer, class_name: "Member", foreign_key: :payer_member_id

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
end
