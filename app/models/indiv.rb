# == Schema Information
#
# Table name: indiv
#
#  recno          :integer          not null
#  indiv_id       :string(12)       not null, primary key
#  sex            :string(1)
#  fullname       :string(255)
#  reli           :string(255)
#  givn           :string(255)
#  surn           :string(255)
#  marnm          :string(255)
#  npfx           :string(255)
#  nsfx           :string(255)
#  notes          :text
#  fams           :string(12)
#  famc           :string(12)
#  birthyear      :integer
#  deathyear      :integer
#  birth_abt      :integer
#  death_abt      :integer
#  odnb           :integer
#  sim20          :text             is an Array
#  birt           :string(200)
#  deat           :string(200)
#  birthdate      :date
#  deathdate      :date
#  perioddist     :integer
#  search_names   :tsvector
#  perioddist_new :integer          is an Array
#  best           :integer
#  dest           :integer
#  bestconf       :integer          is an Array
#  destconf       :integer          is an Array
#  chantext       :string(20)
#  chandate       :date
#  diedyoung      :integer
#  spfx           :string(20)
#


class Indiv < ActiveRecord::Base

  self.table_name = 'indiv'
  self.primary_key = 'recno'

  def sex_enum
    ['M', 'F']
  end

end
