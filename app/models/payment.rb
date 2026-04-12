class Payment < ApplicationRecord
  belongs_to :group
  belongs_to :payer, class_name: "Member", foreign_key: :payer_member_id
  has_many :payment_participants, dependent: :destroy
  has_many :participants, through: :payment_participants, source: :member

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validate :participants_must_exist

  private

  def participants_must_exist
    errors.add(:base, "割り勘対象者を1人以上選択してください") if payment_participants.empty?
  end
end
