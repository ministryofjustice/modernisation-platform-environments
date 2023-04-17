output "acm_certificate" {
  value       = aws_acm_certificate.this
  description = "The aws_acm_certificate resource"
}

output "arn" {
  value       = aws_acm_certificate.this.arn
  description = "The aws_acm_certificate arn"
}

output "validation_records_external" {
  value = {
    for key, value in local.validation_records : key => {
      name   = value.name
      record = value.record
      type   = value.type
    } if value.zone.provider == "external"
  }
  description = "Any DNS validation records that could not be created by the module"
}
