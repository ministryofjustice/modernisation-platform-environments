output "db_role_name" {
  description = "The name of the main database role"
  value       = postgresql_role.main[0].name
}

output "readonly_grant_status" {
  description = "Status of the readonly privileges grant"
  value       = local.setup_user && !var.read_write_role ? "Granted" : "Not Granted"
}

output "read_write_grant_status" {
  description = "Status of the read-write privileges grant"
  value       = local.setup_user && var.read_write_role ? "Granted" : "Not Granted"
}
