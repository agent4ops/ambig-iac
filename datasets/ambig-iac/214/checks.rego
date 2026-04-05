package netflix_high

import rego.v1

bucket_valid(bucket) := true

distribution_valid(distribution, bucket) if {
        some origin in distribution.expressions.origin
        bucket.address in origin.domain_name.references

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

default valid := false

valid if {
        resources := input.configuration.root_module.resources

        some bucket in resources
        bucket.type == "aws_s3_bucket"

        some distribution in resources
        distribution.type == "aws_cloudfront_distribution"

        bucket_valid(bucket)
        distribution_valid(distribution, bucket)
}