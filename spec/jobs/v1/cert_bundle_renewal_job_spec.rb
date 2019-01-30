require 'rails_helper'

RSpec.describe V1::CertBundleRenewalJob, type: :job do
  include OpenSSLHelper

  describe "#perform" do
    it "iterates over all cert bundles and calls obtain_or_renew" do
      cert_needs_renewal = double(
        sub_domain: "foo",
        top_level_domain: "test.com",
        errors: [],
        needs_renewal?: true,
      )
      cert_does_not_need_renewal = double(
        sub_domain: "bar",
        top_level_domain: "test.com",
        errors: [],
        needs_renewal?: false,
      )
      expect(V1::CertBundle).to receive(:all).and_return([cert_needs_renewal, cert_does_not_need_renewal])

      expect(cert_needs_renewal).to receive(:obtain_or_renew)
      expect(cert_does_not_need_renewal).to receive(:obtain_or_renew)
      expect(Rails.logger).to receive(:debug).with("Updating cert bundle for fqdn: #{cert_needs_renewal.sub_domain}.#{cert_needs_renewal.top_level_domain}")
      expect(Rails.logger).to receive(:debug).with("Updating cert bundle for fqdn: #{cert_does_not_need_renewal.sub_domain}.#{cert_does_not_need_renewal.top_level_domain}")

      V1::CertBundleRenewalJob.perform_now
    end

    context "cert renewal failure" do
      it "logs errors while renewing certs" do
        cert_bundle_errors_dbl = double(full_messages: "error messages")
        cert_bundle_dbl = double(
          sub_domain: "foo",
          top_level_domain: "test.com",
          errors: cert_bundle_errors_dbl,
          needs_renewal?: true,
        )
        expect(V1::CertBundle).to receive(:all).and_return([cert_bundle_dbl])
        expect(cert_bundle_errors_dbl).to receive(:empty?).and_return(false)
        expect(cert_bundle_dbl).to receive(:obtain_or_renew)

        expect(Rails.logger).to receive(:debug).with("Updating cert bundle for fqdn: #{cert_bundle_dbl.sub_domain}.#{cert_bundle_dbl.top_level_domain}")
        expect(Rails.logger).to receive(:error).with("[FAILED] Renewing cert bundle for fqdn: #{cert_bundle_dbl.sub_domain}.#{cert_bundle_dbl.top_level_domain}: error messages")

        V1::CertBundleRenewalJob.perform_now
      end
    end
  end
end
