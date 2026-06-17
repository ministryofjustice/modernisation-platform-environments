output "waf_acl_arn" {
  description = "ARN of the WAF Web ACL for ingress ALBs"
  value       = aws_wafv2_web_acl.ingress.arn
}

output "lbc_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.lbc.arn
}
