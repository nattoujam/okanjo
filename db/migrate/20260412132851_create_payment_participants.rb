class CreatePaymentParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_participants do |t|
      t.references :payment, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
    end
    add_index :payment_participants, [ :payment_id, :member_id ], unique: true
  end
end
