class PaymentParticipant < ApplicationRecord
  # 割り勘対象者だけを入れ替えた編集では payments の属性が変わらず updated_at も動かないため、
  # 負担額が変わっても精算結果のキャッシュが更新されない。
  belongs_to :payment, touch: true
  belongs_to :member
end
