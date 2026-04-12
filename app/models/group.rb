class Group < ApplicationRecord
  has_many :members, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :members, reject_if: :all_blank

  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true

  def to_param
    token
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(8)
  end
end
