output "waf_arn" {
  value = var.scope != "CLOUDFRONT" ? aws_wafv2_web_acl.waf[0].arn : aws_wafv2_web_acl.cf[0].arn
}

output "waf_id" {
  value = var.scope != "CLOUDFRONT" ? aws_wafv2_web_acl.waf[0].id : aws_wafv2_web_acl.cf[0].id
}
