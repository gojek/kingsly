require 'rails_helper'

RSpec.describe V1::CertBundleRenewalJob, type: :job do
  include OpenSSLHelper

  describe "#perform" do
    it "iterates over all cert bundles and renews those nearing expiration" do
      cert_bundles_dbl = double
      expect(V1::CertBundle).to receive(:all).and_return(cert_bundles_dbl)

      root_ca_nearing_expiration = generate_root_ca(Time.now + ENV["CERT_BUNDLE_EXPIRY_BUFFER_IN_DAYS"].to_i.days - 1.minute)

      cert_bundle_dbl = double(
        sub_domain: "foo",
        top_level_domain: "test.com",
        full_chain: root_ca_nearing_expiration.to_pem,
        errors: [],
      )
      expect(cert_bundles_dbl).to receive(:each).and_yield(cert_bundle_dbl)

      expect(cert_bundle_dbl).to receive(:obtain_or_renew)
      expect(Rails.logger).to receive(:debug).with("Updating cert bundle for fqdn: #{cert_bundle_dbl.sub_domain}.#{cert_bundle_dbl.top_level_domain}")

      V1::CertBundleRenewalJob.perform_now
    end

    context "cert renewal failure" do
      it "logs errors while renewing certs" do
        cert_bundles_dbl = double
        expect(V1::CertBundle).to receive(:all).and_return(cert_bundles_dbl)

        root_ca_nearing_expiration = generate_root_ca(Time.now + ENV["CERT_BUNDLE_EXPIRY_BUFFER_IN_DAYS"].to_i.days - 1.minute)

        cert_bundle_errors_dbl = double(full_messages: "error messages")

        cert_bundle_dbl = double(
          sub_domain: "foo",
          top_level_domain: "test.com",
          full_chain: root_ca_nearing_expiration.to_pem,
          errors: cert_bundle_errors_dbl,
        )
        expect(cert_bundles_dbl).to receive(:each).and_yield(cert_bundle_dbl)

        expect(cert_bundle_dbl).to receive(:obtain_or_renew)
        expect(cert_bundle_errors_dbl).to receive(:empty?).and_return(false)

        expect(Rails.logger).to receive(:debug).with("Updating cert bundle for fqdn: #{cert_bundle_dbl.sub_domain}.#{cert_bundle_dbl.top_level_domain}")
        expect(Rails.logger).to receive(:error).with("[FAILED] Renewing cert bundle for fqdn: #{cert_bundle_dbl.sub_domain}.#{cert_bundle_dbl.top_level_domain}: error messages")

        V1::CertBundleRenewalJob.perform_now
      end
    end

    it "iterates over all cert bundles and doesn't renew those nearing expiration" do
      cert_bundles_dbl = double
      expect(V1::CertBundle).to receive(:all).and_return(cert_bundles_dbl)

      root_ca_not_nearing_expiration = generate_root_ca(Time.now + ENV["CERT_BUNDLE_EXPIRY_BUFFER_IN_DAYS"].to_i.days + 1.minute)
      cert_bundle_dbl = double(
        sub_domain: "foo",
        top_level_domain: "test.com",
        full_chain: root_ca_not_nearing_expiration.to_pem,
        errors: [],
      )

      expect(cert_bundles_dbl).to receive(:each).and_yield(cert_bundle_dbl)

      expect(cert_bundle_dbl).to_not receive(:obtain_or_renew)
      expect(Rails.logger).to receive(:debug).with("Not updating cert bundle for fqdn: #{cert_bundle_dbl.sub_domain}.#{cert_bundle_dbl.top_level_domain}")

      V1::CertBundleRenewalJob.perform_now
    end
  end
end
