class V1::CertBundle < ApplicationRecord
  validates_uniqueness_of :sub_domain, scope: :top_level_domain
  validates_presence_of :sub_domain, :top_level_domain

  def obtain_or_renew
    self.errors.add(:sub_domain, message: "Cannot be empty") and return if sub_domain.nil?
    self.errors.add(:top_level_domain, message: "Cannot be empty") and return if top_level_domain.nil?
    unless self.needs_renewal?
      Rails.logger.debug("Not updating cert bundle for fqdn: #{self.sub_domain}.#{self.top_level_domain}, not expiring within given buffer time")
      return
    end

    begin
      fqdn = "#{sub_domain}.#{top_level_domain}"
      rate_limit_range = ENV['CERT_RECORD_LIMIT_RANGE_IN_DAYS'] || 7
      rate_limit_count = ENV['CERT_RECORD_LIMIT_COUNT'] || 50

      current_time = Time.now
      cert_record_count = V1::CertRecord.count_from_to(top_level_domain, current_time - rate_limit_range.to_i.days, current_time)
      raise V1::CertRecord::OverprovisionError if cert_record_count >= rate_limit_count.to_i

      acme_service = AcmeService.new
      acme_service.create_order(fqdn)
      dns_challenge = acme_service.dns_challenge

      AwsService.new.update_route53_record!(
        top_level_domain,
        "#{dns_challenge.record_name}.#{fqdn}",
        "\"#{dns_challenge.record_content}\"",
        dns_challenge.record_type,
      )

      acme_service.perform_validation!
      cert_bundle = acme_service.request_certificate!(fqdn)

      update(
        private_key: cert_bundle[:private_key],
        full_chain: cert_bundle[:full_chain],
      )

      # Assume certificate is made even if it's not logged
      Rails.logger.error("[WARNING] Cert record not saved") unless V1::CertRecord.create(top_level_domain: top_level_domain)
    rescue V1::CertRecord::OverprovisionError => error
      Rails.logger.error("[FAILED] TLD Cert: #{error.message}")
      self.errors.add(:tld_cert, message: "#{error.message}")
    rescue Aws::Waiters::Errors::WaiterFailed => error
      Rails.logger.error("[FAILED] AWS route53 record creation: #{error.message}")
      self.errors.add(:route53_updation_failed, message: "#{error.message}")
    rescue StandardError => error
      Rails.logger.error("[FAILED] Standard Error: #{error.message}")
      self.errors.add(:standard_error, message: "#{error.message}")
    end
  end

  def needs_renewal?
    return true if self.full_chain.blank?
    x509 = OpenSSL::X509::Certificate.new(self.full_chain)
    x509.not_after < Time.now + ENV["CERT_BUNDLE_EXPIRY_BUFFER_IN_DAYS"].to_i.days
  end
end
