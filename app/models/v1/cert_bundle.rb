class V1::CertBundle < ApplicationRecord
  validates :fqdn, uniqueness: true
end
