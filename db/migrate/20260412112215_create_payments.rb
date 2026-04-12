class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :group, null: false, foreign_key: true
      t.bigint :payer_member_id, null: false
      t.string :description, null: false
      t.integer :amount, null: false

      t.timestamps
    end
    add_foreign_key :payments, :members, column: :payer_member_id
  end
end
