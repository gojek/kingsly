require 'rails_helper'

RSpec.describe V1::CertRecord, type: :model do
  it { should validate_presence_of(:top_level_domain) }

  before :each do
    V1::CertRecord.destroy_all
  end

  describe "#count_from_to" do
    let(:top_level_domain) { "test.com" }

    it "retrieves only cert record between a certain time" do
      V1::CertRecord.create(top_level_domain: top_level_domain)
      current_time = Time.now
      record_count = V1::CertRecord.count_from_to(top_level_domain, current_time - 1.day, current_time)
      V1::CertRecord.create(top_level_domain: top_level_domain)
      expect(record_count).to eq(1)
    end
  end
end
