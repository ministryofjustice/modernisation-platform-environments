output "access_points" {
  description = "map of aws_efs_access_point resource outputs"
  value       = aws_efs_access_point.this
}

output "file_system" {
  description = "aws_efs_file_system resource output"
  value       = aws_efs_file_system.this
}

output "file_system_policy" {
  description = "aws_efs_file_system_policy output if created, null otherwise"
  value       = length(aws_efs_file_system_policy.this) != 0 ? aws_efs_file_system_policy.this : null
}

output "mount_targets" {
  description = "map of aws_efs_mount_target resource outputs"
  value       = aws_efs_mount_target.this
}
