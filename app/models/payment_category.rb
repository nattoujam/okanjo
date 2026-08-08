class PaymentCategory < ApplicationRecord
  belongs_to :group
  # カテゴリを消しても精算額は変わらないようにするため destroy ではなく nullify にしている
  has_many :payments, dependent: :nullify

  before_validation :assign_sequence, on: :create

  validates :name, presence: true, uniqueness: { scope: :group_id }

  # SQLite の UNIQUE 制約は行ごとに検査されて遅延できないため、
  # [group_id, sequence] の重複を避けるには一度どちらかを未使用の負値へ退避するしかない
  def swap_sequence_with!(other)
    own_sequence, other_sequence = sequence, other.sequence

    self.class.transaction do
      update!(sequence: -own_sequence)
      other.update!(sequence: own_sequence)
      update!(sequence: other_sequence)
    end
  end

  private

  # MAX+1 のレースは Rails が SQLite を BEGIN IMMEDIATE で開く（save 開始時に書き込みロックを取る）ことで防げている
  def assign_sequence
    self.sequence = group&.payment_categories&.maximum(:sequence).to_i + 1
  end
end
