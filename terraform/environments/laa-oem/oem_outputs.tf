output "ami_ec2_laa_oem_app" {
  description = "AMI App"
  value       = data.aws_ami.ec2_laa_oem_app.id
}

output "ami_ec2_laa_oem_db" {
  description = "AMI DB"
  value       = data.aws_ami.ec2_laa_oem_db.id
}

output "ebs_snapshot_oem_app_volume_opt_oem_app" {
  description = "App snapshot /opt/oem/app"
  value       = data.aws_ebs_snapshot.oem_app_volume_opt_oem_app.id
}

output "ebs_snapshot_oem_app_volume_opt_oem_inst" {
  description = "App snapshot /opt/oem/inst"
  value       = data.aws_ebs_snapshot.oem_app_volume_opt_oem_inst.id
}

output "ebs_snapshot_oem_db_volume_opt_oem_app" {
  description = "DB snapshot /opt/oem/app"
  value       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_app.id
}

output "ebs_snapshot_oem_db_volume_opt_oem_inst" {
  description = "DB snapshot /opt/oem/inst"
  value       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_inst.id
}

output "ebs_snapshot_oem_db_volume_opt_oem_dbf" {
  description = "DB snapshot /opt/oem/dbf"
  value       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_dbf.id
}

output "ebs_snapshot_oem_db_volume_opt_oem_redo" {
  description = "DB snapshot /opt/oem/redo"
  value       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_redo.id
}

output "ebs_snapshot_oem_db_volume_opt_oem_arch" {
  description = "DB snapshot /opt/oem/arch"
  value       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_arch.id
}

output "route53_record_app_lb" {
  description = "App LB Route53 record"
  value       = aws_route53_record.route53_record_app_lb.fqdn
}

output "route53_record_app_lb_internal" {
  description = "App internal LB Route53 record"
  value       = aws_route53_record.route53_record_app_lb_internal.fqdn
}

output "route53_record_app_ec2" {
  description = "App Route53 record"
  value       = aws_route53_record.route53_record_app.fqdn
}

output "route53_record_db_ec2" {
  description = "DB Route53 record"
  value       = aws_route53_record.route53_record_db.fqdn
}
