class Charity < ActiveRecord::Base
  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id
  validates_format_of :email_bcc, with: EMAIL_REGEX
  validates_format_of :email_from, with: EMAIL_REGEX

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
      File.read(File.join('views', 'receipt/email.liquid'))
    end
  end

  def pdf_template
    if read_attribute(:pdf_template).present?
      read_attribute(:pdf_template)
    else
      File.read(File.join('views', 'receipt/pdf.liquid'))
    end
  end

  def to_liquid
    attributes
  end
end
