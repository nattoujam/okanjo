class Payment < ApplicationRecord
  belongs_to :group
  belongs_to :payer, class_name: "Member", foreign_key: :payer_member_id
  has_many :payment_participants, dependent: :destroy
  has_many :participants, through: :payment_participants, source: :member

  accepts_nested_attributes_for :payment_participants

  before_validation { self.personal_amount ||= 0 }

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :personal_amount, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :participants_must_exist
  validate :personal_amount_must_be_less_than_amount

  def split_amount
    amount - personal_amount
  end

  private

  def participants_must_exist
    errors.add(:base, "割り勘対象者を1人以上選択してください") if payment_participants.empty?
  end

  def personal_amount_must_be_less_than_amount
    return if amount.nil? || personal_amount.nil?

    errors.add(:base, "自分用の金額は支払い金額未満にしてください") if personal_amount >= amount
  end
end
