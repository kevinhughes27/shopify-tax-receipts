class Charity < ActiveRecord::Base
  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id

  def email_subject
    if read_attribute(:email_subject).present?
      read_attribute(:email_subject)
    else
      "Donation receipt for #{name}"
    end
  end

  def email_template
    if read_attribute(:email_template).present?
      read_attribute(:email_template)
    else
      File.read(File.join('views', 'receipt_email.liquid'))
    end
  end

  def pdf_template
    if read_attribute(:pdf_template).present?
      read_attribute(:pdf_template)
    else
      File.read(File.join('views', 'receipt_pdf.liquid'))
    end
  end

  def to_liquid
    attributes
  end
end
