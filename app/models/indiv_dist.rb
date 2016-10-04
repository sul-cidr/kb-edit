# == Schema Information
#
# Table name: indiv_dist
#
#  create_table "indiv_dist", primary_key: "indiv_id", force: :cascade do |t|
#    t.integer "parentless"
#    t.integer "annan"
#    t.integer "odnb"
#    t.integer "inbred"
#    t.integer "tragedy"
#    t.integer "centrality"
#    t.string  "trarray",        limit: 20
#    t.integer "children"
#    t.integer "marriage"
#    t.integer "odnb_id"
#    t.integer "odnb_wordcount"
#

class IndivDist < ActiveRecord::Base

  self.table_name = 'indiv_dist'
  self.primary_key = 'recno'

  belongs_to :indiv, foreign_key: :indiv_id, primary_key: :indiv_id
  belongs_to :odnb, foreign_key: :odnb_id, primary_key: :odnb_id

  # Validation for string and text fields
  validates_with StringTextValidator

  rails_admin do
    navigation_label 'Debug'
    label 'indiv_dist'
    object_label_method :recno
    weight 100
  end

end
