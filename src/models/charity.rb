class Charity < ActiveRecord::Base
  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id
  validates :receipt_threshold, numericality: { greater_than: 0 }, allow_nil: true
  validates_format_of :email_bcc, with: EMAIL_REGEX, allow_blank: true
  validates_format_of :email_from, with: EMAIL_REGEX, allow_blank: true

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

  def void_email_subject
    if read_attribute(:void__email_subject).present?
      read_attribute(:void_email_subject)
    else
      "Void Donation receipt for #{name}"
    end
  end

  def void_email_template
    if read_attribute(:void_email_template).present?
      read_attribute(:void_email_template)
    else
      File.read(File.join('views', 'receipt/void_email.liquid'))
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
    {
      'name' => name,
      'charity_id' => charity_id
    }
  end
end
