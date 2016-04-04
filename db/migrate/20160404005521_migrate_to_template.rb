class MigrateToTemplate < ActiveRecord::Migration
  def change
    puts "Migrating pdf_body"
    Charity.where.not(pdf_body: '').each do |charity|
      template = charity.pdf_template
      pdf_body = charity.pdf_body

      puts "updating pdf_body to: #{pdf_body}"

      template.gsub!(
        'Donations are tax deductible to the extent permitted by law',
        pdf_body
      )

      charity.update_attributes(pdf_template: template)
    end

    puts "Migrating pdf_signature"
    Charity.where.not(pdf_signature: '').each do |charity|
      template = charity.pdf_template
      pdf_signature = charity.pdf_signature

      puts "updating pdf_signature to: #{pdf_signature}"

      template.gsub!(
        'Thank you',
        pdf_signature
      )

      charity.update_attributes(pdf_template: template)
    end

    puts "Migrating pdf_charity_identifier"
    Charity.where.not(pdf_charity_identifier: '').each do |charity|
      template = charity.pdf_template
      pdf_charity_identifier = charity.pdf_charity_identifier

      puts "updating pdf_charity_identifier to: #{pdf_charity_identifier}"

      template.gsub!(
        'Charity Tax ID #',
        pdf_charity_identifier
      )

      charity.update_attributes(pdf_template: template)
    end
  end
end
