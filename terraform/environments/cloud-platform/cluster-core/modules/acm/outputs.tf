output "certificate_arn" {
  description = "ARN of the ACM certificate attached to this Gateway. Pass this to additional module calls via var.certificate_arn."
  value       = local.certificate_arn
}