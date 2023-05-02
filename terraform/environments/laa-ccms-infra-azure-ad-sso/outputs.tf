output "ami_ec2_ebs_vision_db_app" {
  description = "App AMI"
  value       = data.aws_ami.oracle_ebs_vision_db.id
}

#output "route53_record_app_lb" {
#  description = "App LB Route53 cert validation record"
#  value       = aws_route53_record.ebs_vision_db_lb_cert_validation_record.fqdn
#}

output "route53_record_sg_ebs_vision_a_record" {
  description = "App A record for vision instance"
  value       = aws_route53_record.sg_ebs_vision_db_a_record.name
}

output "route53_record_ebs_vision_db_lb_cname" {
  description = "the output from the lb cname"
  value       = aws_route53_record.ebs_vision_db_lb_cname.fqdn
}
