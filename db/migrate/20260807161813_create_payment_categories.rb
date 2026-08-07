class CreatePaymentCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_categories do |t|
      t.references :group, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :sequence, null: false, default: 0

      t.timestamps
    end
    add_index :payment_categories, [ :group_id, :name ], unique: true
    add_index :payment_categories, [ :group_id, :sequence ], unique: true
  end
end
