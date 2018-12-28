class V1::CertBundleRenewalJob < ApplicationJob
  def perform(*args)
    cert_bundles = V1::CertBundle.all
    cert_bundles.each do |cert_bundle|
      x509 = OpenSSL::X509::Certificate.new(cert_bundle.full_chain)
      if x509.not_after < Time.now + ENV["CERT_BUNDLE_EXPIRY_BUFFER_IN_DAYS"].to_i.days
        Rails.logger.debug("Updating cert bundle for fqdn: #{cert_bundle.sub_domain}.#{cert_bundle.top_level_domain}")
        cert_bundle.obtain_or_renew

        if !cert_bundle.errors.empty?
          Rails.logger.error("[FAILED] Renewing cert bundle for fqdn: #{cert_bundle.sub_domain}.#{cert_bundle.top_level_domain}: #{cert_bundle.errors.full_messages}")
        end
      else
        Rails.logger.debug("Not updating cert bundle for fqdn: #{cert_bundle.sub_domain}.#{cert_bundle.top_level_domain}")
      end
    end
  end
end
