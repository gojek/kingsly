require 'rails_helper'

RSpec.describe V1::CertBundleRenewalJob, type: :job do
  describe "#perform" do
    it "iterates over all cert bundles and renews those nearing expiration" do
      #TODO add test
    end
  end
end
