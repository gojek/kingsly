require 'rails_helper'

RSpec.describe V1::CertBundlesController, type: :controller do
  include AuthHelper
  before(:each) do
    http_login
  end

  describe "POST create" do
    let(:sub_domain) { "foo" }
    let(:top_level_domain) { "test.com" }

    let(:private_key) { "-----BEGIN RSA PRIVATE KEY-----\nFOO...\n-----END RSA PRIVATE KEY-----\n" }
    let(:full_chain) { "-----BEGIN CERTIFICATE-----\nBAR...\n-----END CERTIFICATE-----\n" }

    it "generates a SSL Certificate bundle" do
      cert_bundle_activerecord_relation_dbl = double
      expect(V1::CertBundle).to receive(:where).with(sub_domain: sub_domain, top_level_domain: top_level_domain).and_return (cert_bundle_activerecord_relation_dbl)

      cert_bundle_dbl = double(V1::CertBundle, private_key: private_key, full_chain: full_chain)
      expect(cert_bundle_activerecord_relation_dbl).to receive(:first_or_initialize).and_return (cert_bundle_dbl)
      expect(cert_bundle_dbl).to receive(:obtain_or_renew)
      expect(cert_bundle_dbl).to receive(:errors).and_return([])

      post :create, params: { "top_level_domain" => top_level_domain, "sub_domain" => sub_domain}

      expect(response.status).to eq(200)
      expect(response.body).to eq({private_key: private_key, full_chain: full_chain}.to_json)
    end

    context "on error obtaining or renewing SSL certs" do
      it "responds with internal server error" do
        cert_bundle_activerecord_relation_dbl = double
        expect(V1::CertBundle).to receive(:where).and_return (cert_bundle_activerecord_relation_dbl)

        cert_bundle_dbl = double(V1::CertBundle, private_key: private_key, full_chain: full_chain)
        expect(cert_bundle_activerecord_relation_dbl).to receive(:first_or_initialize).and_return (cert_bundle_dbl)
        expect(cert_bundle_dbl).to receive(:obtain_or_renew)

        cert_bundle_errors_dbl = double(full_messages: "abc")
        expect(cert_bundle_dbl).to receive(:errors).and_return(cert_bundle_errors_dbl).twice
        expect(cert_bundle_errors_dbl).to receive(:empty?).and_return(false)

        post :create, params: { "top_level_domain" => top_level_domain, "sub_domain" => sub_domain}

        expect(response.status).to eq(500)
        expect(response.body).to eq({ message:'error obtaining certs'}.to_json)
      end
    end
  end
end
