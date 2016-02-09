class Charity < ActiveRecord::Base
  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id

  def email_subject
    read_attribute(:email_subject) || "Donation receipt for #{name}"
  end

  def email_template
    read_attribute(:email_template) || File.read(File.join('views', 'receipt_email.liquid'))
  end

  def pdf_body
    read_attribute(:pdf_body) || "Donations are tax deductible to the extent permitted by law"
  end

  def pdf_charity_identifier
    read_attribute(:pdf_charity_identifier) || "Charity Tax ID #"
  end

  def pdf_signature
    read_attribute(:pdf_signature) || ""
  end

  def to_liquid
    attributes
  end
end
