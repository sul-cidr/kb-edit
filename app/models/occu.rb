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

  rails_admin do
    label 'Occupations'
  end

end
