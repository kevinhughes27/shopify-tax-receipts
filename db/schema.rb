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

ActiveRecord::Schema.define(version: 2019_01_27_071032) do

  create_table "charities", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "charity_id", limit: 255
    t.string "shop", limit: 255
    t.text "email_template", limit: 255
    t.string "email_subject", limit: 255
    t.text "pdf_template"
    t.string "email_from", limit: 255
    t.string "email_bcc", limit: 255
    t.string "pdf_filename", default: "donation_receipt"
    t.string "void_email_template"
    t.string "void_email_subject"
    t.decimal "receipt_threshold", precision: 8, scale: 2
    t.string "update_email_template"
    t.string "update_email_subject"
    t.string "donation_id_prefix"
    t.index ["shop"], name: "index_charities_on_shop"
  end

  create_table "donations", force: :cascade do |t|
    t.string "shop"
    t.integer "order_id", limit: 8, null: false
    t.decimal "donation_amount", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "order_number"
    t.string "status"
    t.string "order"
    t.index ["shop"], name: "index_donations_on_shop"
  end

  create_table "products", force: :cascade do |t|
    t.integer "product_id", limit: 8
    t.string "shop", limit: 255
    t.decimal "percentage", default: "100.0"
    t.text "shopify_product"
    t.index ["shop"], name: "index_products_on_shop"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "token_encrypted", limit: 255
    t.index ["name"], name: "index_shops_on_name"
  end

end
