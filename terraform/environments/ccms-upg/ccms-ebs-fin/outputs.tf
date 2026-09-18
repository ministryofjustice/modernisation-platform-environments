output "ebsdb_instance_id" {
  description = "Instance ID of the EBS DB instance — used for terraform import commands"
  value       = module.oracle_ebs_db.instance_id
}

output "ebsapps_instance_ids" {
  description = "Instance IDs of the EBS Apps instances — used for terraform import commands"
  value       = module.oracle_ebs_apps[*].instance_id
}

output "ebsapps_efs_ids" {
  description = "EFS filesystem IDs for the shared /u01, /u03 and /stage apps-tier filesystems — used when mounting on the instances"
  value = {
    u01   = aws_efs_file_system.ebsapps_u01.id
    u03   = aws_efs_file_system.ebsapps_u03.id
    stage = aws_efs_file_system.ebsapps_stage.id
  }
}
