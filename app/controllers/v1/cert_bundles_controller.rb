class V1::CertBundlesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    top_level_domain = params.require(:top_level_domain)
    sub_domain = params.require(:sub_domain)

    cert_bundle = V1::CertBundle.where(top_level_domain: top_level_domain, sub_domain: sub_domain).first_or_initialize
    cert_bundle.obtain_or_renew

    if cert_bundle.errors.empty?
      render status: 200, body: {private_key: cert_bundle.private_key, full_chain: cert_bundle.full_chain}.to_json
    else
      Rails.logger.error("[FAILED] Obtaining cert bundle: #{cert_bundle.errors.full_messages}")
      render status: 500, body: "error obtaining certs"
    end
  end
end
