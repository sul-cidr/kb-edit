# == Schema Information
#
# create_table "indiv_text", primary_key: "indiv_id", force: :cascade do |t|
#   t.text    "occutext"
#   t.text    "notes"
#   t.text    "cause"
#   t.text    "professions"
#   t.text    "tags"
#   t.text    "profnotes"
#   t.text    "prof_sparse"
#   t.integer "recno",        default: "nextval('indiv_text_recno_seq'::regclass)", null: false
#   t.boolean "odnber"
#   t.text    "odnb_prof"
#   t.boolean "lasttag"
#   t.text    "professions2"

class IndivText < ActiveRecord::Base

  self.table_name = 'indiv_text'
  self.primary_key = 'indiv_id'

  belongs_to :indiv, foreign_key: :indiv_id, primary_key: :indiv_id
  # belongs_to :odnb, foreign_key: :odnb_id, primary_key: :odnb

  # Validation for string and text fields
  validates_with StringTextValidator

  rails_admin do
    navigation_label 'Debug'
    label 'indiv_text'
    object_label_method :indiv_id
    weight 100
  end

end
