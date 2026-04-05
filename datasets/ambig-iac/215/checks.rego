package netflix_middle

import data.set
import rego.v1

bucket_valid(bucket) := true

access_control_valid(access_control) if {
	access_control.expressions.name
	access_control.expressions.origin_access_control_origin_type.constant_value == "s3"
	access_control.expressions.signing_behavior
	access_control.expressions.signing_protocol
}

distribution_valid(distribution, access_control, bucket) if {
	some origin in distribution.expressions.origin
	bucket.address in origin.domain_name.references
	access_control.address in origin.origin_access_control_id.references

	some cache_behavior in distribution.expressions.default_cache_behavior
	{method | method := cache_behavior.allowed_methods.constant_value[_]} == {"GET", "HEAD"}
	{method | method := cache_behavior.cached_methods.constant_value[_]} == {"GET", "HEAD"}
	cache_behavior.viewer_protocol_policy.constant_value == "allow-all"

	origin.origin_id == cache_behavior.target_origin_id

	some restrictions in distribution.expressions.restrictions
	some restriction in restrictions.geo_restriction
	restriction.restriction_type
	restriction.locations
}

zone_valid(zone) if {
	zone.expressions.name
}

record_valid(record, zone, distribution) if {
	record.expressions.type
	record.expressions.name
	zone.address in record.expressions.zone_id.references

	some alias in record.expressions.alias
	distribution.address in alias.name.references
	distribution.address in alias.zone_id.references
	alias.evaluate_target_health
}

default valid := false

valid if {
	resources := input.configuration.root_module.resources

	some bucket in resources
	bucket.type == "aws_s3_bucket"

	some access_control in resources
	access_control.type == "aws_cloudfront_origin_access_control"

	some distribution in resources
	distribution.type == "aws_cloudfront_distribution"

	some zone in resources
	zone.type == "aws_route53_zone"

	some record in resources
	record.type == "aws_route53_record"

	bucket_valid(bucket)
	access_control_valid(access_control)
	distribution_valid(distribution, access_control, bucket)
	zone_valid(zone)
	record_valid(record, zone, distribution)
}