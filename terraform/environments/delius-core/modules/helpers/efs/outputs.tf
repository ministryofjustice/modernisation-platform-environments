output "fs_arn" {
  value = aws_efs_file_system.this.arn
}

output "fs_id" {
  description = "id that identifies the file system"
  value       = aws_efs_file_system.this.id
}

output "sg_id" {
  value = aws_security_group.default.id
}

output "sg_arn" {
  value = aws_security_group.default.arn
}

output "access_point_id" {
  value = aws_efs_access_point.efs_access_point.id
}

output "name" {
  value = var.name
}
