class Charity < ActiveRecord::Base
  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  validates :shop, uniqueness: true
  validates_presence_of :name, :charity_id
  validates :receipt_threshold, numericality: { greater_than: 0 }, allow_nil: true
  validates_format_of :email_bcc, with: EMAIL_REGEX, allow_blank: true
  validates_format_of :email_from, with: EMAIL_REGEX, allow_blank: true

  def self.attr_or_default(attr, default)
    define_method(attr) do
      if read_attribute(attr).present?
        read_attribute(attr)
      else
        default
      end
    end
  end

  attr_or_default :donation_id_prefix, '#'

  attr_or_default :email_subject, "Donation receipt for #{name}"
  attr_or_default :email_template, File.read(File.join('views', 'receipt/email.liquid'))

  attr_or_default :update_email_subject, "Donation receipt for #{name}"
  attr_or_default :update_email_template, File.read(File.join('views', 'receipt/update_email.liquid'))

  attr_or_default :void_email_subject, "Void Donation receipt for #{name}"
  attr_or_default :void_email_template, File.read(File.join('views', 'receipt/void_email.liquid'))

  attr_or_default :pdf_template, File.read(File.join('views', 'receipt/pdf.liquid'))

  def to_liquid
    {
      'name' => name,
      'charity_id' => charity_id,
      'donation_id_prefix' => donation_id_prefix
    }
  end
end
