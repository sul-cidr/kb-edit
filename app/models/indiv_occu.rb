# == Schema Information
#
# Table name: indiv_occu
#
#  recno     :integer          not null, primary key
#  indiv_id  :string(12)
#  occu_text :string(30)
#

class IndivOccu < ActiveRecord::Base

  self.table_name = 'indiv_occu'
  self.primary_key = 'recno'

  belongs_to :indiv, foreign_key: :indiv_id, primary_key: :indiv_id
  belongs_to :occu, foreign_key: :occu_text, primary_key: :class_

  # Validation for string and text fields
  validates_with StringTextValidator

  rails_admin do
    navigation_label 'Debug'
    label 'indiv_id'
    object_label_method :recno
    weight 100

  end
end
