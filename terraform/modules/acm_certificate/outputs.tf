output "acm_certificate" {
  value       = aws_acm_certificate.this
  description = "The aws_acm_certificate resource"
}

output "arn" {
  value       = aws_acm_certificate.this.arn
  description = "The aws_acm_certificate arn"
}

output "validation_records_external" {
  value       = local.validation_records_external
  description = "Any DNS validation records that could not be created by the module"
}
