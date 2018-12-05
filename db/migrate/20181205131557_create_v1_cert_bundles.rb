class CreateV1CertBundles < ActiveRecord::Migration[5.2]
  def change
    create_table :v1_cert_bundles do |t|
      t.text :fqdn
      t.text :private_key
      t.text :full_chain

      t.timestamps
    end
  end
end
