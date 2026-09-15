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
