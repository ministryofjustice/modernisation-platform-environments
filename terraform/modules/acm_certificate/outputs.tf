output "aws_acm_certificate" {
  value       = aws_acm_certificate.this
  description = "The aws_acm_certificate resource"
}

output "arn" {
  value       = aws_acm_certificate.this.arn
  description = "The aws_acm_certificate arn"
}
