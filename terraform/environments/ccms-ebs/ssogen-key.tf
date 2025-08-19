# Generate SSH key pair in Terraform (RSA 4096)
resource "tls_private_key" "ssogen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create EC2 key pair
resource "aws_key_pair" "ssogen" {
  key_name   = "ssogen_key_name"
  public_key = tls_private_key.ssogen.public_key_openssh

  tags = {
    Name        = "ssogen-key"
    Environment = local.environment
  }
}

# KMS key to encrypt the secret
resource "aws_kms_key" "ssogen_kms" {
  description         = "KMS for SSH private keys in Secrets Manager"
  enable_key_rotation = true
  tags = {
    Environment = local.environment
  }
}

# Secrets Manager secret metadata
resource "aws_secretsmanager_secret" "ssogen_privkey" {
  name       = "ssh/${local.environment}/ssogen/private-key"
  kms_key_id = aws_kms_key.ssogen_kms.arn
  recovery_window_in_days = 7

  tags = {
    Environment = local.environment
    Purpose     = "ec2-ssh"
  }
}

# Store the private key securely in Secrets Manager
resource "aws_secretsmanager_secret_version" "ssogen_privkey_v1" {
  secret_id = aws_secretsmanager_secret.ssogen_privkey.id
  secret_string = jsonencode({
    private_key_pem = tls_private_key.ssogen.private_key_pem
    public_key      = tls_private_key.ssogen.public_key_openssh
    fingerprint_md5 = tls_private_key.ssogen.public_key_fingerprint_md5
    key_type        = "rsa"
    key_name        = aws_key_pair.ssogen.key_name
    environment     = local.environment
    region          = data.aws_region.current.name
    created_at_utc  = timestamp()
  })
}
