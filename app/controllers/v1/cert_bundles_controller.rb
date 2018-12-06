class V1::CertBundlesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    top_level_domain = params.require(:top_level_domain)
    sub_domain = params.require(:sub_domain)
    fqdn = "#{sub_domain}.#{top_level_domain}"

    acme_service = AcmeService.new
    acme_service.create_order(fqdn)
    dns_challenge = acme_service.dns_challenge

    begin
      AwsService.new.create_route53_record!(
        top_level_domain,
        "#{dns_challenge.record_name}.#{fqdn}",
        "\"#{dns_challenge.record_content}\"",
        dns_challenge.record_type,
      )

      acme_service.perform_validation!
      cert_bundle = acme_service.request_certificate!(fqdn)

      V1::CertBundle.create(
        fqdn: fqdn,
        private_key: cert_bundle[:private_key],
        full_chain: cert_bundle[:full_chain],
      )

      render status: 200, body: {private_key: cert_bundle[:private_key], full_chain: cert_bundle[:full_chain]}.to_json
    rescue Aws::Waiters::Errors::WaiterFailed => error
      Rails.logger.error("[FAILED] AWS route53 record creation: #{error.message}")
      render status: 500, body: "aws route53 record creation failed"
      return
    rescue StandardError => error
      Rails.logger.error(error)
      render status: 500, body: nil
      return
    end
  end
end
