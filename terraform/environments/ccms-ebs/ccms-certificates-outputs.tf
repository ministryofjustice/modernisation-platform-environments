output "aws_acm_certificate-external-arn" {
  description = "aws_acm_certificate external arn"
  value       = aws_acm_certificate.external.arn
}

output "aws_acm_certificate-external-domain_name" {
  description = "aws_acm_certificate external domain_name"
  value       = aws_acm_certificate.external.domain_name
}

output "aws_acm_certificate-external-not_after" {
  description = "aws_acm_certificate external not_after"
  value       = aws_acm_certificate.external.not_after
}

output "aws_acm_certificate-external-status" {
  description = "aws_acm_certificate external status"
  value       = aws_acm_certificate.external.status
}

#

output "aws_acm_certificate-external-service-arn" {
  description = "aws_acm_certificate external-service arn"
  value       = aws_acm_certificate.external-service.arn
}

output "aws_acm_certificate-external-service-domain_name" {
  description = "aws_acm_certificate external-service domain_name"
  value       = aws_acm_certificate.external-service.domain_name
}

output "aws_acm_certificate-external-service-not_after" {
  description = "aws_acm_certificate external-service not_after"
  value       = aws_acm_certificate.external-service.not_after
}

output "aws_acm_certificate-external-service-status" {
  description = "aws_acm_certificate external-service status"
  value       = aws_acm_certificate.external-service.status
}

#

output "aws_route53_record-external_validation-fqdn" {
  description = "aws_route53_record external_validation fqdn"
  value       = aws_route53_record.external_validation.fqdn
}

output "aws_route53_record-external_validation-name" {
  description = "aws_route53_record external_validation name"
  value       = aws_route53_record.external_validation.name
}

#

output "aws_acm_certificate_validation-external-id" {
  description = "aws_acm_certificate_validation external id"
  value       = aws_acm_certificate_validation.external.id
}
