class V1::CertBundlesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    top_level_domain = params.require(:top_level_domain)
    sub_domain = params.require(:sub_domain)
    fqdn = "#{sub_domain}.#{top_level_domain}"

    acme_client_private_key = OpenSSL::PKey::RSA.new(ENV["ACME_CLIENT_PRIVATE_KEY"])

    acme_client = Acme::Client.new(private_key: acme_client_private_key, directory: ENV["ACME_CLIENT_DIR"])
    acme_client.new_account(contact: ENV["LETSENCRYPT_CONTACT"], terms_of_service_agreed: true)
    acme_client_order = acme_client.new_order(identifiers: [fqdn])
    authorization = acme_client_order.authorizations.first
    dns_challenge = authorization.dns
    Rails.logger.info("created dns challenge")

    aws_client = Aws::Route53::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    hosted_zone_id = ""
    aws_host_zones = aws_client.list_hosted_zones
    aws_host_zones.hosted_zones.each do |hosted_zone|
      if hosted_zone.name == top_level_domain + "."
        hosted_zone_id = hosted_zone.id
      end
    end
    Rails.logger.info("got hosted zone id #{hosted_zone_id}")

    resp = aws_client.change_resource_record_sets({
      change_batch: {
        changes: [
          {
            action: "UPSERT",
            resource_record_set: {
              name: "#{dns_challenge.record_name}.#{fqdn}",
              resource_records: [
                {
                  value: "\"#{dns_challenge.record_content}\"",
                },
              ],
              ttl: 60,
              type: dns_challenge.record_type,
            },
          },
        ]
      },
      hosted_zone_id: hosted_zone_id,
    })
    Rails.logger.info("submitted TXT record to route53 #{resp}")

    begin
      aws_client.wait_until(:resource_record_sets_changed, {id: resp["change_info"]["id"]})
      Rails.logger.info("route53 change created")
    rescue Aws::Waiters::Errors::WaiterFailed => error
      Rails.logger.error("failed waiting for change to be created: #{error.message}")
      render status: 500, body: "aws route53 record creation failed"
      return
    end

    dns_challenge.request_validation
    while dns_challenge.status == 'pending'
      sleep(2)
      dns_challenge.reload
    end
    Rails.logger.info("performed dns challenge validation")

    if dns_challenge.status != "valid"
      render status: 500, body: "dns challenge failed"
      return
    end

    private_key = OpenSSL::PKey::RSA.new(4096)
    csr = Acme::Client::CertificateRequest.new(private_key: private_key, subject: { common_name: fqdn })
    acme_client_order.finalize(csr: csr)
    sleep(1) while acme_client_order.status == 'processing'

    if acme_client_order.status != "valid"
      render status: 500, body: "CSR failed"
      return
    end

    V1::CertBundle.create(
      fqdn: fqdn,
      private_key: private_key.to_s,
      full_chain: acme_client_order.certificate,
    )

    render status: 200, body: {private_key: private_key.to_s, full_chain: acme_client_order.certificate}.to_json
  end
end
