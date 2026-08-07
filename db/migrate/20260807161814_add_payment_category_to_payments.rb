class AddPaymentCategoryToPayments < ActiveRecord::Migration[8.1]
  def change
    add_reference :payments, :payment_category, foreign_key: true
  end
end
