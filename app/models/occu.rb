# == Schema Information
#
# Table name: occu
#
#  recno        :integer          not null, primary key
#  parent_class :string(100)
#  class_       :string(100)
#  is_parent    :boolean
#

class Occu < ActiveRecord::Base

  self.table_name = 'occu'
  self.primary_key = 'recno'

  # Validation for string and text fields
  validates_with StringTextValidator

  rails_admin do
    label 'Occupation'
    object_label_method :class_
  end

end
