class AcmeService
  def initialize
    acme_client_private_key = OpenSSL::PKey::RSA.new(ENV["ACME_CLIENT_PRIVATE_KEY"])
    @acme_client = Acme::Client.new(private_key: acme_client_private_key, directory: ENV["ACME_CLIENT_DIR"])
  end

  def create_order(fqdn)
    @acme_client.new_account(contact: ENV["LETSENCRYPT_CONTACT"], terms_of_service_agreed: true)

    Rails.logger.info("created dns challenge")
    @acme_order = @acme_client.new_order(identifiers: [fqdn])
  end

  def dns_challenge
    @dns_challenge = @acme_order.authorizations.first.dns
    return @dns_challenge
  end

  def perform_validation!
    @dns_challenge.request_validation
    while @dns_challenge.status == 'pending'
      sleep(2)
      @dns_challenge.reload
    end

    raise "DNS challenge validation failed" if @dns_challenge.status != "valid"
    Rails.logger.info("performed dns challenge validation")
  end

  def request_certificate!(fqdn)
    private_key = OpenSSL::PKey::RSA.new(4096)
    csr = Acme::Client::CertificateRequest.new(private_key: private_key, subject: { common_name: fqdn })
    @acme_order.finalize(csr: csr)

    sleep(1) while @acme_order.status == 'processing'

    raise "[FAILED] Requesting certificate for fqdn: #{fqdn}" if @acme_order.status != "valid"
    return {private_key: private_key.to_s, full_chain: @acme_order.certificate}
  end
end
