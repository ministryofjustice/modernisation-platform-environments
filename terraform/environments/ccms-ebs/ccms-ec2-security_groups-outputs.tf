output "aws_security_group_ec2_sg_ebsdb_arn" {
  description = "aws_security_group ec2_sg_ebsdb arn"
  value       = aws_security_group.ec2_sg_ebsdb.arn
}

#

output "aws_security_group_ec2_sg_ebsapps_arn" {
  description = "aws_security_group ec2_sg_ebsapps arn"
  value       = aws_security_group.ec2_sg_ebsapps.arn
}

#

output "aws_security_group_ec2_sg_webgate_arn" {
  description = "aws_security_group ec2_sg_webgate arn"
  value       = aws_security_group.ec2_sg_webgate.arn
}

#

output "aws_security_group_ec2_sg_accessgate_arn" {
  description = "aws_security_group ec2_sg_accessgate arn"
  value       = aws_security_group.ec2_sg_accessgate.arn
}

#

output "aws_security_group_sg_ebsapps_lb_arn" {
  description = "aws_security_group sg_ebsapps_lb arn"
  value       = aws_security_group.sg_ebsapps_lb.arn
}

#

output "aws_security_group_ec2_sg_ftp_arn" {
  description = "aws_security_group ec2_sg_ftp arn"
  value       = aws_security_group.ec2_sg_ftp.arn
}

#

output "aws_security_group_ec2_sg_clamav_arn" {
  description = "aws_security_group ec2_sg_clamav arn"
  value       = aws_security_group.ec2_sg_clamav.arn
}

#

# output "aws_security_group_sg_webgate_lb_arn" {
#   description = "aws_security_group sg_webgate_lb arn"
#   value       = aws_security_group.sg_webgate_lb.arn
# }
