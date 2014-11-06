class Charity < ActiveRecord::Base
  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id

  def email_subject
    read_attribute(:email_subject) || "Donation receipt for #{name}"
  end

  def email_template
    read_attribute(:email_template) || File.read(File.join('views', 'receipt_email.liquid'))
  end

  def to_liquid
    attributes
  end
end
