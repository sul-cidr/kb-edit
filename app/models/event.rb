# == Schema Information
#
# Table name: event
#
#  recno             :integer          not null, primary key
#  indiv_id          :string(12)
#  label             :text
#  class             :string(12)
#  type              :string(50)
#  period_text       :string(50)
#  place             :text
#  cause             :text
#  notes             :text
#  event_date        :date
#  year              :integer
#  year_abt          :integer
#  actor_id          :string(12)
#  year_est          :integer
#  verb              :string(30)
#  place_id          :integer
#  search_col        :tsvector
#  befaft            :integer
#  year_est_pass     :integer
#  period_array      :date             is an Array
#  event_period_year :integer
#


class Event < ActiveRecord::Base

  self.table_name = 'event'
  self.primary_key = 'recno'

end
