class Charity < ActiveRecord::Base
  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id

  def email_subject
    read_attribute(:email_subject) || "Donation receipt for #{name}"
  end

  def email_template
    read_attribute(:email_template) || File.read(File.join('views', 'receipt_email.liquid'))
  end

  def pdf_template
    read_attribute(:email_template) || File.read(File.join('views', 'receipt_pdf.liquid'))
  end

  def to_liquid
    body = if read_attribute(:pdf_body).present?
      read_attribute(:pdf_body)
    else
      'Donations are tax deductible to the extent permitted by law'
    end

    charity_identifier = if read_attribute(:pdf_charity_identifier).present?
      read_attribute(:pdf_charity_identifier)
    else
      'Charity Tax ID #'
    end

    attributes.merge({
      'pdf_body' => body,
      'pdf_signature' => read_attribute(:pdf_signature),
      'pdf_charity_identifier' => charity_identifier
    })
  end
end
