require './config/boot'
require './config/environment'

module Clockwork
  every(ENV["CERT_BUNDLE_RENEWAL_PERIOD_IN_SECONDS"].to_i.second, 'cert_bundle_renewal.perform') { V1::CertBundleRenewalJob.perform_now }
end
