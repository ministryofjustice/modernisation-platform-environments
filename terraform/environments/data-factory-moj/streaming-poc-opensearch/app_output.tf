output "vpn_endpoint_id" {
  description = "Client VPN Endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.this[*].id
}

output "vpn_endpoint_dns" {
  description = "Client VPN Endpoint DNS name"
  value       = aws_ec2_client_vpn_endpoint.this[*].dns_name
}

output "vpn_client_cert" {
  description = "VPN Client Certificate"
  value       = tls_locally_signed_cert.vpn_client[*].cert_pem
  sensitive   = true
}

output "vpn_client_key" {
  description = "VPN Client Private Key"
  value       = tls_private_key.vpn_client[*].private_key_pem
  sensitive   = true
}
