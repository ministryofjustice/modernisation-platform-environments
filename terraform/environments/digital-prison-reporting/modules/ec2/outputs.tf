# tflint-ignore-file: terraform_required_version, terraform_required_providers

output "private_key" {
  value     = tls_private_key.ec2-user.private_key_pem
  sensitive = true
}
