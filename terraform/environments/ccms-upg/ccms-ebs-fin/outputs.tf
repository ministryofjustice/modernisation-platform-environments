output "ebsdb_instance_id" {
  description = "Instance ID of the EBS DB instance — used for terraform import commands"
  value       = module.oracle_ebs_db.instance_id
}

output "ebsapps_instance_ids" {
  description = "Instance IDs of the EBS Apps instances — used for terraform import commands"
  value       = module.oracle_ebs_apps[*].instance_id
}
