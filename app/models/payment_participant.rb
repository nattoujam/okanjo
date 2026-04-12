class PaymentParticipant < ApplicationRecord
  belongs_to :payment
  belongs_to :member
end
