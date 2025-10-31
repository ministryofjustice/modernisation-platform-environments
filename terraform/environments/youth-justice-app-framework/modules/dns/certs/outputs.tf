output "domain_cert_arn" {
  description = "ARN of the certificate"
  value       = aws_acm_certificate.domain_cert.arn
}
