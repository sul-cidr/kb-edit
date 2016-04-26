# == Schema Information
#
# Table name: place
#
#  placeid   :integer          not null, primary key
#  parentid  :integer
#  dbname    :string(255)
#  prefname  :string(255)
#  altnames  :text
#  latitude  :decimal(, )
#  longitude :decimal(, )
#  geonameid :integer
#  featclass :string(1)
#  featcode  :string(10)
#  ccode     :string(2)
#  mod_date  :date
#  admin1    :string(100)
#  admin2    :string(100)
#


class Place < ActiveRecord::Base

  self.table_name = 'place'
  self.primary_key = 'placeid'

  rails_admin do

    label 'Place'

    # list do
    #   include_fields :placeid, :dbname
    # end

  end

end
