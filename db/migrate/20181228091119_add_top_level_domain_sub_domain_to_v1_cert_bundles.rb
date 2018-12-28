class AddTopLevelDomainSubDomainToV1CertBundles < ActiveRecord::Migration[5.2]
  def change
    add_column :v1_cert_bundles, :top_level_domain, :text
    add_column :v1_cert_bundles, :sub_domain, :text
  end
end
