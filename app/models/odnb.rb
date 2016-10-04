# == Schema Information
#
# Table name: odnb
#
#  create_table "odnb", primary_key: "odnb_id", force: :cascade do |t|
#    t.string "odnb_name", limit: 256
#

class Odnb < ActiveRecord::Base

  self.table_name = 'odnb'
  self.primary_key = 'odnb_id'

  # Validation for string and text fields
  validates_with StringTextValidator

  rails_admin do
    navigation_label 'Debug'
    label 'odnb'
    object_label_method :odnb_id
    weight 100
  end

end
