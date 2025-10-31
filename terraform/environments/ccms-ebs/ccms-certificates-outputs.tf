output "aws_acm_certificate-external-arn" {
  description = "aws_acm_certificate external arn"
  value       = try(aws_acm_certificate.external[*].arn, "None")
}

output "aws_acm_certificate-external-domain_name" {
  description = "aws_acm_certificate external domain_name"
  value       = try(aws_acm_certificate.external[*].domain_name, "None")
}

output "aws_acm_certificate-external-not_after" {
  description = "aws_acm_certificate external not_after"
  value       = try(aws_acm_certificate.external[*].not_after, "None")
}

output "aws_acm_certificate-external-status" {
  description = "aws_acm_certificate external status"
  value       = try(aws_acm_certificate.external[*].status, "None")
}

#

# output "aws_acm_certificate-external-service-arn" {
#   description = "aws_acm_certificate external-service arn"
#   value       = try(aws_acm_certificate.external-service[*].arn, "None")
# }

# output "aws_acm_certificate-external-service-domain_name" {
#   description = "aws_acm_certificate external-service domain_name"
#   value       = try(aws_acm_certificate.external-service[*].domain_name, "None")
# }

# output "aws_acm_certificate-external-service-not_after" {
#   description = "aws_acm_certificate external-service not_after"
#   value       = try(aws_acm_certificate.external-service[*].not_after, "None")
# }

# output "aws_acm_certificate-external-service-status" {
#   description = "aws_acm_certificate external-service status"
#   value       = try(aws_acm_certificate.external-service[*].status, "None")
# }

#

# output "aws_route53_record-external_validation-fqdn" {
#   description = "aws_route53_record external_validation fqdn"
#   value       = try(aws_route53_record.external_validation[*].fqdn, "None")
# }

# output "aws_route53_record-external_validation-name" {
#   description = "aws_route53_record external_validation name"
#   value       = try(aws_route53_record.external_validation[*].name, "None")
# }

#

# output "aws_acm_certificate_validation-external-id" {
#   description = "aws_acm_certificate_validation external id"
#   value       = try(aws_acm_certificate_validation.external[*].id, "None")
# }
