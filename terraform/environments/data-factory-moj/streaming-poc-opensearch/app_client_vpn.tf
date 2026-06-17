resource "aws_acm_certificate" "vpn_server" {
  private_key       = tls_private_key.vpn_server.private_key_pem
  certificate_body  = tls_locally_signed_cert.vpn_server.cert_pem
  certificate_chain = tls_self_signed_cert.vpn_ca.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "vpn_client" {
  private_key       = tls_private_key.vpn_client.private_key_pem
  certificate_body  = tls_locally_signed_cert.vpn_client.cert_pem
  certificate_chain = tls_self_signed_cert.vpn_ca.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "vpn_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "vpn_ca" {
  private_key_pem = tls_private_key.vpn_ca.private_key_pem

  subject {
    common_name  = "vpn.ca"
    organization = "moj-${local.name}"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "tls_private_key" "vpn_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "vpn_server" {
  private_key_pem = tls_private_key.vpn_server.private_key_pem

  subject {
    common_name  = "vpn.server"
    organization = "moj-${local.name}"
  }
}

resource "tls_locally_signed_cert" "vpn_server" {
  cert_request_pem   = tls_cert_request.vpn_server.cert_request_pem
  ca_private_key_pem = tls_private_key.vpn_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.vpn_ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_private_key" "vpn_client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "vpn_client" {
  private_key_pem = tls_private_key.vpn_client.private_key_pem

  subject {
    common_name  = "vpn.client"
    organization = "moj-${local.name}"
  }
}

resource "tls_locally_signed_cert" "vpn_client" {
  cert_request_pem   = tls_cert_request.vpn_client.cert_request_pem
  ca_private_key_pem = tls_private_key.vpn_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.vpn_ca.cert_pem

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "aws_cloudwatch_log_group" "vpn" {
  name              = "/aws/clientvpn/${local.name}"
  retention_in_days = var.flowlog_retention_in_days
  kms_key_id        = aws_kms_key.flow_logs.arn
}

resource "aws_cloudwatch_log_stream" "vpn" {
  name           = "connections"
  log_group_name = aws_cloudwatch_log_group.vpn.name
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = "Client VPN for ${local.name}"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block      = "172.16.0.0/22" # VPN client IP range

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn.name
  }

  dns_servers = [cidrhost(data.aws_vpc.shared.cidr_block, 2)] # VPC DNS

  split_tunnel = true
  vpc_id       = data.aws_vpc.shared.id

  security_group_ids = [aws_security_group.vpn.id]
}

#tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group" "vpn" {
  name_prefix = "${local.name}-vpn-"
  description = "Security group for Client VPN"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "OpenVPN from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Access to VPC resources"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ec2_client_vpn_network_association" "this" {
  count                  = length(data.aws_subnets.shared-private.ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = data.aws_subnets.shared-private.ids[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "this" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = data.aws_vpc.shared.cidr_block
  authorize_all_groups   = true
}

