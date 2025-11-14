output "aws_route53_record_external_fqdn" {
  description = "aws_route53_record external fqdn"
  value       = aws_route53_record.external[*].fqdn
}

#

output "aws_route53_record_prod_ebsapp_lb_fqdn" {
  description = "aws_route53_record prod_ebsapp_lb fqdn"
  value       = aws_route53_record.prod_ebsapp_lb[*].fqdn
}

#

output "aws_route53_record_ebslb_cname_fqdn" {
  description = "aws_route53_record ebslb_cname fqdn"
  value       = aws_route53_record.ebslb_cname[*].fqdn
}

#

output "aws_route53_record_ebsdb_fqdn" {
  description = "aws_route53_record ebsdb fqdn"
  value       = aws_route53_record.ebsdb.fqdn
}

#

output "aws_route53_record_prod_ebsdb_fqdn" {
  description = "aws_route53_record prod_ebsdb fqdn"
  value       = aws_route53_record.prod_ebsdb[*].fqdn
}

#

output "aws_route53_record_ebsapps_fqdn" {
  description = "aws_route53_record ebsapps fqdn"
  value       = aws_route53_record.ebsapps[*].fqdn
}

#

output "aws_route53_record_prod_ebsapps_fqdn" {
  description = "aws_route53_record prod_ebsapps fqdn"
  value       = aws_route53_record.prod_ebsapps[*].fqdn
}

#

# output "aws_route53_record_ebswgate_fqdn" {
#   description = "aws_route53_record ebswgate fqdn"
#   value       = aws_route53_record.ebswgate[*].fqdn
# }

#

# output "aws_route53_record_prod_ebswgate_fqdn" {
#   description = "aws_route53_record prod_ebswgate fqdn"
#   value       = aws_route53_record.prod_ebswgate[*].fqdn
# }

#

output "aws_route53_record_webgate_ec2_fqdn" {
  description = "aws_route53_record webgate_ec2 fqdn"
  value       = aws_route53_record.webgate_ec2[*].fqdn
}

#

output "aws_route53_record_prod_webgate_ec2_fqdn" {
  description = "aws_route53_record prod_webgate_ec2 fqdn"
  value       = aws_route53_record.prod_webgate_ec2[*].fqdn
}

#

output "aws_route53_record_accessgate_ec2_fqdn" {
  description = "aws_route53_record accessgate_ec2 fqdn"
  value       = aws_route53_record.accessgate_ec2[*].fqdn
}

#

output "aws_route53_record_prod_accessgate_ec2_fqdn" {
  description = "aws_route53_record prod_accessgate_ec2 fqdn"
  value       = aws_route53_record.prod_accessgate_ec2[*].fqdn
}

#

output "aws_route53_record_clamav_fqdn" {
  description = "aws_route53_record clamav fqdn"
  value       = aws_route53_record.clamav.fqdn
}

#

output "aws_route53_record_prod_clamav_fqdn" {
  description = "aws_route53_record prod_clamav fqdn"
  value       = aws_route53_record.prod_clamav[*].fqdn
}
