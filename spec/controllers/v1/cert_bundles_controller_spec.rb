require 'rails_helper'

RSpec.describe V1::CertBundlesController, type: :controller do
  include AuthHelper
  before(:each) do
    http_login
  end

  describe "POST create" do
    let(:sub_domain) { "something" }
    let(:top_level_domain) { "abc.com" }

    it "generates a SSL Certificate bundle" do

      acme_service_dbl = double(AcmeService)
      expect(AcmeService).to receive(:new).and_return(acme_service_dbl)
      expect(acme_service_dbl).to receive(:create_order)

      dns_challenge_double = double
      expect(acme_service_dbl).to receive(:dns_challenge).and_return(dns_challenge_double)
      expect(dns_challenge_double).to receive(:record_name)
      expect(dns_challenge_double).to receive(:record_type)
      expect(dns_challenge_double).to receive(:record_content)

      aws_service_dbl = double(AwsService)
      expect(AwsService).to receive(:new).and_return(aws_service_dbl)
      expect(aws_service_dbl).to receive(:create_route53_record!)

      expect(acme_service_dbl).to receive(:perform_validation!)
      expect(acme_service_dbl).to receive(:request_certificate!)
        .and_return({private_key: "pvt-key", full_chain: "full-chain"})

      expect(V1::CertBundle).to receive(:create)

      post :create, params: { "top_level_domain" => top_level_domain, "sub_domain" => sub_domain}

      expect(response.status).to eq(200)
      expect(response.body).to eq({"private_key"=>"pvt-key", "full_chain"=>"full-chain"}.to_json)
    end
  end
end
