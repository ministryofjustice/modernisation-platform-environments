output "aws_ses_domain_identity_domain_identity_verification_token" {
  description = "aws_ses_domain_identity domain_identity verification_token"
  value       = aws_ses_domain_identity.domain_identity.verification_token
}

output "aws_ses_domain_dkim_domain_identity_dkim_tokens" {
  description = "aws_ses_domain_dkim domain_identity dkim_tokens"
  value       = aws_ses_domain_dkim.domain_identity.dkim_tokens
}
