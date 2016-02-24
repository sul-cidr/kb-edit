# == Schema Information
#
# Table name: indiv
#
#  recno          :integer          not null, primary key
#  indiv_id       :string(12)       not null
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

  has_many :indiv_occus, foreign_key: :indiv_id, primary_key: :indiv_id
  has_many :occus, through: :indiv_occus

  before_create :set_indiv_id

  rails_admin do

    label 'Individual'
    object_label_method :fullname

    list do
      include_fields :indiv_id, :fullname
    end

    edit do
      exclude_fields :recno, :indiv_id, :indiv_occus
    end

  end

  #
  # Gender select options.
  #
  def sex_enum
    ['M', 'F']
  end

  private

  #
  # Set the next "I<int>" id.
  #
  def set_indiv_id

    ids = self.class.all.pluck(:indiv_id).map do |id|
      id.gsub('I', '').to_i
    end

    self.indiv_id = "I#{ids.max+1}"

  end

end
