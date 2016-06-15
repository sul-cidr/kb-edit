# == Schema Information
#
# Table name: event
#
#  recno             :integer          not null, primary key
#  indiv_id          :string(12)
#  label             :text
#  class_            :string(12)
#  type_             :string(50)
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

  has_many :particips, primary_key: :recno, foreign_key: :event_id
  has_many :indivs, :through => :particips

  # accepts_nested_attributes_for :indivs, :allow_destroy => true
  # attr_accessible :indiv_ids
  has_one :place, primary_key: :place_id, foreign_key: :placeid

  rails_admin do
    label 'Event'
    object_label_method :label

    configure :indivs do

    end
  end

  #
  # Type select options.
  #
  def type__enum
    self.class.uniq.pluck(:type_).sort()
  end

  def evlabel
    self.type_ + '_' + self.recno.to_s
  end
end
