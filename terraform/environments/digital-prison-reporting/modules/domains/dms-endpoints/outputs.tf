output "dms_target_endpoint_arn" {
  value = var.setup_dms_endpoints && setup_dms_s3_endpoint ? join("", aws_dms_endpoint.dms-s3-target-endpoint.*.endpoint_arn): ""
}

output "dms_source_endpoint_arn" {
  value = var.setup_dms_endpoints && setup_dms_nomis_endpoint ? join("", aws_dms_endpoint.dms-s3-target-source.*.endpoint_arn): ""
}