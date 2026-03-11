output "user_name" {
  description = "The username of the SFTP user"
  value       = aws_transfer_user.this.user_name
}
