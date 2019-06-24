class CreateV1CertRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :v1_cert_records do |t|
      t.string :top_level_domain, presence: true

      t.timestamps
    end
  end
end
