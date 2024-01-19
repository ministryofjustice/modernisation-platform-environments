output "aws_instance_ec2_oracle_ebs_arn" {
  description = "aws_instance ec2_oracle_ebs arn"
  value       = aws_instance.ec2_oracle_ebs.arn
}

output "aws_instance_ec2_oracle_ebs_private_dns" {
  description = "aws_instance ec2_oracle_ebs private_dns"
  value       = aws_instance.ec2_oracle_ebs.private_dns
}

output "aws_instance_ec2_oracle_ebs_private_ip" {
  description = "aws_instance ec2_oracle_ebs private_ip"
  value       = aws_instance.ec2_oracle_ebs.private_ip
}

#

output "aws_ebs_volume_export_home_arn" {
  description = "aws_ebs_volume export_home arn"
  value       = aws_ebs_volume.export_home.arn
}

#

output "aws_volume_attachment_export_home_att_device_name" {
  description = "aws_volume_attachment export_home_att device_name"
  value       = aws_volume_attachment.export_home_att.device_name
}

output "aws_volume_attachment_export_home_att_instance_id" {
  description = "aws_volume_attachment export_home_att instance_id"
  value       = aws_volume_attachment.export_home_att.instance_id
}

output "aws_volume_attachment_export_home_att_volume_id" {
  description = "aws_volume_attachment export_home_att volume_id"
  value       = aws_volume_attachment.export_home_att.volume_id
}

#

output "aws_ebs_volume_u01_arn" {
  description = "aws_ebs_volume u01 arn"
  value       = aws_ebs_volume.u01.arn
}

#

output "aws_volume_attachment_u01_att_device_name" {
  description = "aws_volume_attachment u01_att device_name"
  value       = aws_volume_attachment.u01_att.device_name
}

output "aws_volume_attachment_u01_att_instance_id" {
  description = "aws_volume_attachment u01_att instance_id"
  value       = aws_volume_attachment.u01_att.instance_id
}

output "aws_volume_attachment_u01_att_volume_id" {
  description = "aws_volume_attachment u01_att volume_id"
  value       = aws_volume_attachment.u01_att.volume_id
}

#

output "aws_ebs_volume_arch_arn" {
  description = "aws_ebs_volume arch arn"
  value       = aws_ebs_volume.arch.arn
}

#

output "aws_volume_attachment_arch_att_device_name" {
  description = "aws_volume_attachment arch_att device_name"
  value       = aws_volume_attachment.arch_att.device_name
}

output "aws_volume_attachment_arch_att_instance_id" {
  description = "aws_volume_attachment arch_att instance_id"
  value       = aws_volume_attachment.arch_att.instance_id
}

output "aws_volume_attachment_arch_att_volume_id" {
  description = "aws_volume_attachment arch_att volume_id"
  value       = aws_volume_attachment.arch_att.volume_id
}

#

#output "aws_ebs_volume_dbf_arn" {
#  description = "aws_ebs_volume dbf arn"
#  value       = aws_ebs_volume.dbf.arn
#}

#

#output "aws_volume_attachment_dbf_att_device_name" {
#  description = "aws_volume_attachment dbf_att device_name"
#  value       = aws_volume_attachment.dbf_att.device_name
#}

#output "aws_volume_attachment_dbf_att_instance_id" {
#  description = "aws_volume_attachment dbf_att instance_id"
#  value       = aws_volume_attachment.dbf_att.instance_id
#}

#output "aws_volume_attachment_dbf_att_volume_id" {
#  description = "aws_volume_attachment dbf_att volume_id"
#  value       = aws_volume_attachment.dbf_att.volume_id
#}

#

output "aws_ebs_volume_redoA_arn" {
  description = "aws_ebs_volume redoA arn"
  value       = aws_ebs_volume.redoA.arn
}

#

output "aws_volume_attachment_redoA_att_device_name" {
  description = "aws_volume_attachment redoA_att device_name"
  value       = aws_volume_attachment.redoA_att.device_name
}

output "aws_volume_attachment_redoA_att_instance_id" {
  description = "aws_volume_attachment redoA_att instance_id"
  value       = aws_volume_attachment.redoA_att.instance_id
}

output "aws_volume_attachment_redoA_att_volume_id" {
  description = "aws_volume_attachment redoA_att volume_id"
  value       = aws_volume_attachment.redoA_att.volume_id
}

#

output "aws_ebs_volume_techst_arn" {
  description = "aws_ebs_volume techst arn"
  value       = aws_ebs_volume.techst.arn
}

#

output "aws_volume_attachment_techst_att_device_name" {
  description = "aws_volume_attachment techst_att device_name"
  value       = aws_volume_attachment.techst_att.device_name
}

output "aws_volume_attachment_techst_att_instance_id" {
  description = "aws_volume_attachment techst_att instance_id"
  value       = aws_volume_attachment.techst_att.instance_id
}

output "aws_volume_attachment_techst_att_volume_id" {
  description = "aws_volume_attachment techst_att volume_id"
  value       = aws_volume_attachment.techst_att.volume_id
}

#

output "aws_ebs_volume_backup_arn" {
  description = "aws_ebs_volume backup arn"
  value       = aws_ebs_volume.backup.arn
}

#

output "aws_volume_attachment_backup_att_device_name" {
  description = "aws_volume_attachment backup_att device_name"
  value       = aws_volume_attachment.backup_att.device_name
}

output "aws_volume_attachment_backup_att_instance_id" {
  description = "aws_volume_attachment backup_att instance_id"
  value       = aws_volume_attachment.backup_att.instance_id
}

output "aws_volume_attachment_backup_att_volume_id" {
  description = "aws_volume_attachment backup_att volume_id"
  value       = aws_volume_attachment.backup_att.volume_id
}

#

output "aws_ebs_volume_redoB_arn" {
  description = "aws_ebs_volume redoB arn"
  value       = aws_ebs_volume.redoB.arn
}

#

output "aws_volume_attachment_redoB_att_device_name" {
  description = "aws_volume_attachment redoB_att device_name"
  value       = aws_volume_attachment.redoB_att.device_name
}

output "aws_volume_attachment_redoB_att_instance_id" {
  description = "aws_volume_attachment redoB_att instance_id"
  value       = aws_volume_attachment.redoB_att.instance_id
}

output "aws_volume_attachment_redoB_att_volume_id" {
  description = "aws_volume_attachment redoB_att volume_id"
  value       = aws_volume_attachment.redoB_att.volume_id
}

#

output "aws_ebs_volume_diag_arn" {
  description = "aws_ebs_volume diag arn"
  value       = aws_ebs_volume.diag.arn
}

#

output "aws_volume_attachment_diag_att_device_name" {
  description = "aws_volume_attachment diag_att device_name"
  value       = aws_volume_attachment.diag_att.device_name
}

output "aws_volume_attachment_diag_att_instance_id" {
  description = "aws_volume_attachment diag_att instance_id"
  value       = aws_volume_attachment.diag_att.instance_id
}

output "aws_volume_attachment_diag_att_volume_id" {
  description = "aws_volume_attachment diag_att volume_id"
  value       = aws_volume_attachment.diag_att.volume_id
}

#

#output "aws_cloudwatch_metric_alarm_disk_free_ebsdb_ccms_ebs_dbf_arn" {
#  description = "aws_cloudwatch_metric_alarm disk_free_ebsdb_ccms_ebs_dbf arn"
#  value       = aws_cloudwatch_metric_alarm.disk_free_ebsdb_ccms_ebs_dbf.arn
#}

#output "aws_cloudwatch_metric_alarm_disk_free_ebsdb_ccms_ebs_dbf_id" {
#  description = "aws_cloudwatch_metric_alarm disk_free_ebsdb_ccms_ebs_dbf id"
#  value       = aws_cloudwatch_metric_alarm.disk_free_ebsdb_ccms_ebs_dbf.id
#}
