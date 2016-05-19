# == Schema Information
#
# Table name: particip
#
#  recno    :integer          not null, primary key
#  event_id :integer          not null
#  actor_id :string(12)
#  role     :string(12)
#  extent   :string(12)
#

class Particip < ActiveRecord::Base

  self.table_name = 'particip'
  self.primary_key = 'recno'

  belongs_to :event, foreign_key: :event_id
  belongs_to :indiv, foreign_key: :actor_id, primary_key: :indiv_id

  rails_admin do
    label 'Participation'
  end

  #
  # Role select options.
  #
  def role_enum
    self.class.uniq.pluck(:role)
  end

  #
  # Extent select options.
  #
  def extent_enum
    self.class.uniq.pluck(:extent)
  end

end
