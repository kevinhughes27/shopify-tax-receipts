class Charity < ActiveRecord::Base
  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id

  def to_liquid
    attributes
  end
end
