# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_12_111102) do
  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "memo"
    t.string "name", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_groups_on_token", unique: true
  end

  create_table "members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_members_on_group_id"
  end

  add_foreign_key "members", "groups"
end
