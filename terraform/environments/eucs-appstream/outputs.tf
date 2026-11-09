output "equip_workspaces_registration_code" {
  value       = try(module.equip_workspaces[0].registration_code, null)
  description = "WorkSpaces registration code for the Entra app relay state URL."
}

output "equip_workspaces_directory_id" {
  value = try(module.equip_workspaces[0].workspaces_directory_id, null)
}

output "equip_workspaces_security_group_id" {
  value = try(module.equip_workspaces[0].security_group_id, null)
}

output "nexthink_connector_role_arn" {
  value       = try(aws_iam_role.nexthink_connector[0].arn, null)
  description = "Paste into the AWS Role ARN field of the Nexthink AWS IAM connector credential."
}
