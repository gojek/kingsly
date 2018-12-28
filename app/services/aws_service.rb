class AwsService
  def initialize
    @aws_client = Aws::Route53::Client.new(
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
  end

  def update_route53_record!(top_level_domain, fqdn, record_content, record_type)
    hosted_zone_id = get_hosted_zone_id!(top_level_domain)

    resp = @aws_client.change_resource_record_sets({
      change_batch: {
        changes: [
          {
            action: "UPSERT",
            resource_record_set: {
              name: fqdn,
              resource_records: [
                {
                  value: record_content,
                },
              ],
              ttl: 60,
              type: record_type,
            },
          },
        ],
      },
      hosted_zone_id: hosted_zone_id,
    })
    Rails.logger.info("submitted TXT record to route53 #{resp}")

    @aws_client.wait_until(:resource_record_sets_changed, {id: resp["change_info"]["id"]})
    Rails.logger.info("route53 change created")
  end

  private
  def get_hosted_zone_id!(top_level_domain)
    aws_host_zones = @aws_client.list_hosted_zones

    aws_host_zones.hosted_zones.each do |hosted_zone|
      if hosted_zone.name == top_level_domain + "."
        Rails.logger.info("got hosted zone id #{hosted_zone.id} for top level domain #{top_level_domain}")
        return hosted_zone.id
      end
    end

    raise "Hosted zone id not found for #{top_level_domain}"
  end
end
