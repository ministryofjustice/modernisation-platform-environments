output "private_key" {
  value     = nonsensitive(tls_private_key.ec2-user.private_key_pem)
#  sensitive = true
}