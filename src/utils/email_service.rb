def deliver_donation_receipt(shop, charity, donation, pdf, to = nil)
  to ||= donation.email
  bcc = charity.email_bcc
  from = charity.email_from || shop.email

  subject = charity.email_subject
  body = email_body(charity.email_template, charity, donation)
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

def email_body(template, charity, donation)
  liquid(
    template,
    layout: false,
    locals: {
      charity: charity,
      donation: donation,
      order: donation.order_to_liquid
      }
    )
end

def send_email(to, bcc, from, subject, body, pdf, filename)
  Pony.mail to: to,
            bcc: bcc,
            from: from,
            subject: subject,
            attachments: {"#{filename}.pdf" => pdf},
            body: body
end
