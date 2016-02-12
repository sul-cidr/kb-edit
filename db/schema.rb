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

ActiveRecord::Schema.define(version: 0) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "edges", primary_key: "recno", force: :cascade do |t|
    t.string "target",   limit: 16
    t.string "source",   limit: 16
    t.string "relation", limit: 100
  end

  create_table "event", primary_key: "recno", force: :cascade do |t|
    t.string   "indiv_id",          limit: 12
    t.text     "label"
    t.string   "class",             limit: 12
    t.string   "type",              limit: 50
    t.string   "period_text",       limit: 50
    t.text     "place"
    t.text     "cause"
    t.text     "notes"
    t.date     "event_date"
    t.integer  "year"
    t.integer  "year_abt"
    t.string   "actor_id",          limit: 12
    t.integer  "year_est"
    t.string   "verb",              limit: 30
    t.integer  "place_id"
    t.tsvector "search_col"
    t.integer  "befaft"
    t.integer  "year_est_pass"
    t.date     "period_array",                 array: true
    t.integer  "event_period_year"
  end

  add_index "event", ["indiv_id"], name: "idx_eventindiv", using: :btree
  add_index "event", ["place"], name: "idx_eplace", using: :btree
  add_index "event", ["search_col"], name: "eventsearch_idx", using: :gin

  create_table "family", primary_key: "recno", force: :cascade do |t|
    t.string "fam_id",       limit: 16
    t.string "f_husb",       limit: 12
    t.string "f_wife",       limit: 12
    t.string "f_chil_array",             array: true
    t.string "f_children",   limit: 200
  end

  add_index "family", ["fam_id"], name: "idx_famid", using: :btree

  create_table "imagepath", id: false, force: :cascade do |t|
    t.string "image_id", limit: 12
    t.string "path",     limit: 256
    t.string "title",    limit: 256
    t.text   "note"
  end

  create_table "indiv", primary_key: "indiv_id", force: :cascade do |t|
    t.integer  "recno",                      default: "nextval('indiv_recno_seq'::regclass)", null: false
    t.string   "sex",            limit: 1
    t.string   "fullname",       limit: 255
    t.string   "reli",           limit: 255
    t.string   "givn",           limit: 255
    t.string   "surn",           limit: 255
    t.string   "marnm",          limit: 255
    t.string   "npfx",           limit: 255
    t.string   "nsfx",           limit: 255
    t.text     "notes"
    t.string   "fams",           limit: 12
    t.string   "famc",           limit: 12
    t.integer  "birthyear"
    t.integer  "deathyear"
    t.integer  "birth_abt"
    t.integer  "death_abt"
    t.integer  "odnb"
    t.text     "sim20",                                                                                    array: true
    t.string   "birt",           limit: 200
    t.string   "deat",           limit: 200
    t.date     "birthdate"
    t.date     "deathdate"
    t.integer  "perioddist"
    t.tsvector "search_names"
    t.integer  "perioddist_new",                                                                           array: true
    t.integer  "best"
    t.integer  "dest"
    t.integer  "bestconf",                                                                                 array: true
    t.integer  "destconf",                                                                                 array: true
    t.string   "chantext",       limit: 20
    t.date     "chandate"
    t.integer  "diedyoung"
    t.string   "spfx",           limit: 20
  end

  create_table "indiv_dist", primary_key: "indiv_id", force: :cascade do |t|
    t.integer "parentless"
    t.integer "annan"
    t.integer "odnb"
    t.integer "inbred"
    t.integer "tragedy"
    t.integer "centrality"
    t.string  "trarray",        limit: 20
    t.integer "children"
    t.integer "marriage"
    t.integer "odnb_id"
    t.integer "odnb_wordcount"
  end

  create_table "indiv_events", primary_key: "indiv_id", force: :cascade do |t|
    t.text "particip_array"
  end

  create_table "indiv_image", id: false, force: :cascade do |t|
    t.string "indiv_id", limit: 12
    t.string "image_id", limit: 12
  end

  create_table "indiv_occu", primary_key: "recno", force: :cascade do |t|
    t.string "indiv_id", limit: 12
    t.string "occu",     limit: 30
  end

  create_table "indiv_text", primary_key: "indiv_id", force: :cascade do |t|
    t.text    "occutext"
    t.text    "notes"
    t.text    "cause"
    t.text    "professions"
    t.text    "tags"
    t.text    "profnotes"
    t.text    "prof_sparse"
    t.integer "recno",        default: "nextval('indiv_text_recno_seq'::regclass)", null: false
    t.boolean "odnber"
    t.text    "odnb_prof"
    t.boolean "lasttag"
    t.text    "professions2"
  end

  create_table "occu", primary_key: "recno", force: :cascade do |t|
    t.string  "parent_class", limit: 100
    t.string  "class_",       limit: 100
    t.boolean "is_parent"
  end

  create_table "odnb", primary_key: "odnb_id", force: :cascade do |t|
    t.string "odnb_name", limit: 256
  end

  create_table "particip", primary_key: "recno", force: :cascade do |t|
    t.integer "event_id",            null: false
    t.string  "actor_id", limit: 12
    t.string  "role",     limit: 12
    t.string  "extent",   limit: 12
  end

  add_index "particip", ["event_id"], name: "particip_event_id_idx", using: :btree

  create_table "photos", id: false, force: :cascade do |t|
    t.integer  "id",                     default: "nextval('photos_id_seq'::regclass)", null: false
    t.string   "needs_xy",     limit: 1
    t.string   "gallery_id"
    t.string   "g_title"
    t.integer  "photo_id",     limit: 8
    t.string   "address"
    t.string   "p_title"
    t.string   "description"
    t.string   "coordinates"
    t.string   "tags"
    t.string   "neighborhood"
    t.string   "locality"
    t.string   "img_orig"
    t.date     "date_posted"
    t.datetime "date_taken"
    t.string   "url_flickr"
    t.integer  "license"
    t.string   "owner_id"
    t.string   "owner_name"
    t.string   "owner_real"
    t.string   "path_alias"
    t.text     "notes"
  end

  create_table "place", primary_key: "placeid", force: :cascade do |t|
    t.integer "parentid"
    t.string  "dbname",    limit: 255
    t.string  "prefname",  limit: 255
    t.text    "altnames"
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "geonameid"
    t.string  "featclass", limit: 1
    t.string  "featcode",  limit: 10
    t.string  "ccode",     limit: 2
    t.date    "mod_date",              default: "(now())::date"
    t.string  "admin1",    limit: 100
    t.string  "admin2",    limit: 100
  end

  add_index "place", ["dbname"], name: "idx_dbname", using: :btree

  create_table "s_uk4326", primary_key: "gid", force: :cascade do |t|
    t.integer  "objectid"
    t.string   "admin_name", limit: 50
    t.string   "gmi_admin2", limit: 75
    t.string   "country",    limit: 16
    t.geometry "geom",       limit: {:srid=>0, :type=>"geometry"}
    t.tsvector "search"
  end

  create_table "sims", primary_key: "indiv_id", force: :cascade do |t|
    t.string "sim_id", array: true
  end

end
