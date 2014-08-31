class Charity < ActiveRecord::Base
  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id
end