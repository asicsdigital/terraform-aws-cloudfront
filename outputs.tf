# Outputs

output "cloudfront_id" {
  value = aws_cloudfront_distribution.cf_distribution.0.id
}

output "cloudfront_arn" {
  value = aws_cloudfront_distribution.cf_distribution.0.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cf_distribution.0.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.cf_distribution.0.hosted_zone_id
}
