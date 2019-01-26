require 'tilt/liquid'

def deliver_donation_receipt(shop, charity, donation, pdf, to = nil)
  to ||= donation.email
  bcc = charity.email_bcc
  from = charity.email_from || shop.email

  subject = charity.email_subject
  body = email_body(charity.email_template, charity, donation)
  filename = charity.pdf_filename

  send_email(to, bcc, from, subject, body, pdf, filename)
end

def deliver_updated_receipt(shop, charity, donation, pdf, to = nil)
  to ||= donation.email
  bcc = charity.email_bcc
  from = charity.email_from || shop.email

  subject = charity.update_email_subject
  body = email_body(charity.update_email_template, charity, donation)
  filename = charity.pdf_filename

  send_email(to, bcc, from, subject, body, pdf, filename)
end

def deliver_void_receipt(shop, charity, donation, pdf, to = nil)
  to ||= donation.email
  bcc = charity.email_bcc
  from = charity.email_from || shop.email

  subject = charity.void_email_subject
  body = email_body(charity.void_email_template, charity, donation)
  filename = charity.pdf_filename

  send_email(to, bcc, from, subject, body, pdf, filename)
end

def email_body(email_template, charity, donation)
  template = Tilt::LiquidTemplate.new { |t| email_template }

  template.render(
    charity: charity,
    donation: donation,
    order: donation.order_to_liquid
  )
end

def send_email(to, bcc, from, subject, body, pdf, filename)
  options = {
    to: to,
    bcc: bcc,
    from: from,
    subject: subject,
    attachments: {"#{filename}.pdf" => pdf}
  }

  if body.include?("</html>")
    options[:html_body] = body
  else
    options[:body] = body
  end

  Pony.mail(options)
end
