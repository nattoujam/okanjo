class AddPersonalAmountToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :personal_amount, :integer, null: false, default: 0
  end
end
