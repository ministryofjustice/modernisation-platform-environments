output "grant_iam_role_arn" {
  description = "ARN for Grant Location IAM Role"
  value       = aws_iam_role.s3.arn
}

output "cloudfront_waf_acl" {
  description = "ARN for ACL to attach to Cloudfront WAF"
  value       = aws_wafv2_web_acl.this.arn
}
