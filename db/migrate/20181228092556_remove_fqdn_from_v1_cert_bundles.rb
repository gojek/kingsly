class RemoveFqdnFromV1CertBundles < ActiveRecord::Migration[5.2]
  def change
    remove_column :v1_cert_bundles, :fqdn
  end
end
