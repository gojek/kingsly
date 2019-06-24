class V1::CertRecord < ApplicationRecord
  validates_presence_of :top_level_domain

  def self.count_from_to(top_level_domain, from_time, to_time)
    self
      .where(top_level_domain: top_level_domain, created_at: from_time..to_time)
      .count
  end

  class OverprovisionError < StandardError
    def message
      "TLD cert overprovisioned"
    end
  end
end
