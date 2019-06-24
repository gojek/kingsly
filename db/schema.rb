# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_17_042653) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "v1_cert_bundles", force: :cascade do |t|
    t.text "private_key"
    t.text "full_chain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "top_level_domain"
    t.text "sub_domain"
  end

  create_table "v1_cert_records", force: :cascade do |t|
    t.string "top_level_domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
