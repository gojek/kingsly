class V1::CertBundleRenewalJob < ApplicationJob
  def perform(*args)
    cert_bundles = V1::CertBundle.all
    cert_bundles.each do |cert_bundle|
      Rails.logger.debug("Updating cert bundle for fqdn: #{cert_bundle.sub_domain}.#{cert_bundle.top_level_domain}")
      cert_bundle.obtain_or_renew

      if !cert_bundle.errors.empty?
        Rails.logger.error("[FAILED] Renewing cert bundle for fqdn: #{cert_bundle.sub_domain}.#{cert_bundle.top_level_domain}: #{cert_bundle.errors.full_messages}")
      end
    end
  end
end
