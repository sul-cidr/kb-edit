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

end
