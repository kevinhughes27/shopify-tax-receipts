# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20171019183557) do

  create_table "charities", force: true do |t|
    t.string "name"
    t.string "charity_id"
    t.string "shop"
    t.text   "email_template", limit: 255
    t.string "email_subject"
    t.text   "pdf_template"
    t.string "email_from"
    t.string "email_bcc"
  end

  add_index "charities", ["shop"], name: "index_charities_on_shop"

  create_table "products", force: true do |t|
    t.integer "product_id", limit: 8
    t.string  "shop"
    t.decimal "percentage",           default: 100.0
  end

  add_index "products", ["shop"], name: "index_products_on_shop"

  create_table "shops", force: true do |t|
    t.string "name"
    t.string "token_encrypted"
  end

  add_index "shops", ["name"], name: "index_shops_on_name"

end
