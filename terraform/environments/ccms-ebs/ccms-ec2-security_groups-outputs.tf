output "aws_security_group_ec2_sg_ebsdb_arn" {
  description = "aws_security_group ec2_sg_ebsdb arn"
  value       = aws_security_group.ec2_sg_ebsdb.arn
}

#

output "aws_security_group_rule_ingress_traffic_ebsdb_id" {
  description = "aws_security_group_rule ingress_traffic_ebsdb id"
  value       = aws_security_group_rule.ingress_traffic_ebsdb[*].id
}

#

output "aws_security_group_rule_egress_traffic_ebsdb_sg_id" {
  description = "aws_security_group_rule egress_traffic_ebsdb_sg id"
  value       = aws_security_group_rule.egress_traffic_ebsdb_sg[*].id
}

#

output "aws_security_group_rule_egress_traffic_ebsdb_cidr_id" {
  description = "aws_security_group_rule egress_traffic_ebsdb_cidr id"
  value       = aws_security_group_rule.egress_traffic_ebsdb_cidr[*].id
}

#

output "aws_security_group_ec2_sg_ebsapps_arn" {
  description = "aws_security_group ec2_sg_ebsapps arn"
  value       = aws_security_group.ec2_sg_ebsapps.arn
}

#

output "aws_security_group_rule_ingress_traffic_ebsapps_id" {
  description = "aws_security_group_rule ingress_traffic_ebsapps id"
  value       = aws_security_group_rule.ingress_traffic_ebsapps[*].id
}

#

output "aws_security_group_rule_egress_traffic_ebsapps_sg_id" {
  description = "aws_security_group_rule egress_traffic_ebsapps_sg id"
  value       = aws_security_group_rule.egress_traffic_ebsapps_sg[*].id
}

#

output "aws_security_group_rule_egress_traffic_ebsapps_cidr_id" {
  description = "aws_security_group_rule egress_traffic_ebsapps_cidr id"
  value       = aws_security_group_rule.egress_traffic_ebsapps_cidr[*].id
}

#

output "aws_security_group_ec2_sg_webgate_arn" {
  description = "aws_security_group ec2_sg_webgate arn"
  value       = aws_security_group.ec2_sg_webgate.arn
}

#

output "aws_security_group_rule_ingress_traffic_webgate_id" {
  description = "aws_security_group_rule ingress_traffic_webgate id"
  value       = aws_security_group_rule.ingress_traffic_webgate[*].id
}

#

output "aws_security_group_rule_egress_traffic_webgate_sg_id" {
  description = "aws_security_group_rule egress_traffic_webgate_sg id"
  value       = aws_security_group_rule.egress_traffic_webgate_sg[*].id
}

#

output "aws_security_group_rule_egress_traffic_webgate_cidr_id" {
  description = "aws_security_group_rule egress_traffic_webgate_cidr id"
  value       = aws_security_group_rule.egress_traffic_webgate_cidr[*].id
}

#

output "aws_security_group_ec2_sg_accessgate_arn" {
  description = "aws_security_group ec2_sg_accessgate arn"
  value       = aws_security_group.ec2_sg_accessgate.arn
}

#

output "aws_security_group_rule_ingress_traffic_accessgate_id" {
  description = "aws_security_group_rule ingress_traffic_accessgate id"
  value       = aws_security_group_rule.ingress_traffic_accessgate[*].id
}

#

output "aws_security_group_rule_egress_traffic_accessgate_sg_id" {
  description = "aws_security_group_rule egress_traffic_accessgate_sg id"
  value       = aws_security_group_rule.egress_traffic_accessgate_sg[*].id
}

#

output "aws_security_group_rule_egress_traffic_accessgate_cidr_id" {
  description = "aws_security_group_rule egress_traffic_accessgate_cidr id"
  value       = aws_security_group_rule.egress_traffic_accessgate_cidr[*].id
}

#

output "aws_security_group_sg_ebsapps_lb_arn" {
  description = "aws_security_group sg_ebsapps_lb arn"
  value       = aws_security_group.sg_ebsapps_lb.arn
}

#

output "aws_security_group_rule_ingress_traffic_ebslb_id" {
  description = "aws_security_group_rule ingress_traffic_ebslb id"
  value       = aws_security_group_rule.ingress_traffic_ebslb[*].id
}

#

output "aws_security_group_rule_egress_traffic_ebslb_sg_id" {
  description = "aws_security_group_rule egress_traffic_ebslb_sg id"
  value       = aws_security_group_rule.egress_traffic_ebslb_sg[*].id
}

#

output "aws_security_group_rule_egress_traffic_ebslb_cidr_id" {
  description = "aws_security_group_rule egress_traffic_ebslb_cidr id"
  value       = aws_security_group_rule.egress_traffic_ebslb_cidr[*].id
}

#

output "aws_security_group_ec2_sg_ftp_arn" {
  description = "aws_security_group ec2_sg_ftp arn"
  value       = aws_security_group.ec2_sg_ftp.arn
}

#

output "aws_security_group_rule_ingress_traffic_ftp_id" {
  description = "aws_security_group_rule ingress_traffic_ftp id"
  value       = aws_security_group_rule.ingress_traffic_ftp[*].id
}

#

output "aws_security_group_rule_egress_traffic_ftp_id" {
  description = "aws_security_group_rule egress_traffic_ftp id"
  value       = aws_security_group_rule.egress_traffic_ftp[*].id
}

#

output "aws_security_group_ec2_sg_clamav_arn" {
  description = "aws_security_group ec2_sg_clamav arn"
  value       = aws_security_group.ec2_sg_clamav.arn
}

#

output "aws_security_group_rule_ingress_traffic_clamav_id" {
  description = "aws_security_group_rule ingress_traffic_clamav id"
  value       = aws_security_group_rule.ingress_traffic_clamav[*].id
}

#

output "aws_security_group_rule_egress_traffic_clamav_id" {
  description = "aws_security_group_rule egress_traffic_clamav id"
  value       = aws_security_group_rule.egress_traffic_clamav[*].id
}

#

output "aws_security_group_rule_all_internal_ingress_traffic_id" {
  description = "aws_security_group_rule all_internal_ingress_traffic id"
  value       = aws_security_group_rule.all_internal_ingress_traffic[*].id
}

#

output "aws_security_group_rule_all_internal_egress_traffic_id" {
  description = "aws_security_group_rule all_internal_egress_traffic id"
  value       = aws_security_group_rule.all_internal_egress_traffic[*].id
}

#

output "aws_security_group_sg_webgate_lb_arn" {
  description = "aws_security_group sg_webgate_lb arn"
  value       = aws_security_group.sg_webgate_lb.arn
}

#

output "aws_security_group_rule_ingress_traffic_webgatelb_id" {
  description = "aws_security_group_rule ingress_traffic_webgatelb id"
  value       = aws_security_group_rule.ingress_traffic_webgatelb[*].id
}

#

output "aws_security_group_rule_egress_traffic_webgatelb_sg_id" {
  description = "aws_security_group_rule egress_traffic_webgatelb_sg id"
  value       = aws_security_group_rule.egress_traffic_webgatelb_sg[*].id
}

#

output "aws_security_group_rule_egress_traffic_webgatelb_cidr_id" {
  description = "aws_security_group_rule egress_traffic_webgatelb_cidr id"
  value       = aws_security_group_rule.egress_traffic_webgatelb_cidr[*].id
}
