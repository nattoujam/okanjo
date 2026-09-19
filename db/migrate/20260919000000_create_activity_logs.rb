class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :group, null: false, foreign_key: true, index: false
      t.string :action, null: false
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.json :before
      t.json :after
      t.datetime :created_at, null: false
    end

    add_index :activity_logs, [ :group_id, :created_at ]
  end
end
