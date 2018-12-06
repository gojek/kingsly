require 'rails_helper'

RSpec.describe V1::CertBundle, type: :model do
  it { should validate_uniqueness_of(:fqdn) }
end
