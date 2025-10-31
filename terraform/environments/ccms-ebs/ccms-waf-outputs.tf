output "aws_wafv2_ip_set_ebs_waf_ip_set_arn" {
  description = "aws_wafv2_ip_set ebs_waf_ip_set arn"
  value       = aws_wafv2_ip_set.ebs_waf_ip_set.arn
}

output "aws_wafv2_ip_set_ebs_waf_ip_set_id" {
  description = "aws_wafv2_ip_set ebs_waf_ip_set id"
  value       = aws_wafv2_ip_set.ebs_waf_ip_set.id
}

#

output "aws_wafv2_web_acl_ebs_web_acl_arn" {
  description = "aws_wafv2_web_acl ebs_web_acl arn"
  value       = aws_wafv2_web_acl.ebs_web_acl.arn
}

output "aws_wafv2_web_acl_ebs_web_acl_id" {
  description = "aws_wafv2_web_acl ebs_web_acl id"
  value       = aws_wafv2_web_acl.ebs_web_acl.id
}

#

output "aws_cloudwatch_log_group_ebs_waf_logs_arn" {
  description = "aws_cloudwatch_log_group ebs_waf_logs arn"
  value       = aws_cloudwatch_log_group.ebs_waf_logs.arn
}

#

output "aws_wafv2_web_acl_logging_configuration_ebs_waf_logging_id" {
  description = "aws_wafv2_web_acl_logging_configuration ebs_waf_logging id"
  value       = aws_wafv2_web_acl_logging_configuration.ebs_waf_logging.id
}
