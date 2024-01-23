output "arn" {
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