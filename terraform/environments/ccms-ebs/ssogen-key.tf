# checkov:skip=CKV_AWS_356: KMS key policies require Resource="*" by design; scope via principals & conditions.
data "aws_iam_policy_document" "ssogen_kms_policy" {
  # 1) Admin: keep root full control (required to avoid lockout)
  statement {
    sid = "AllowRootAccountAdmin"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
# checkov:skip=CKV_AWS_109: Root admin required to prevent key lockout; functional access is tightly scoped to EC2 role via conditions.
  # 2) Allow SSOGEN EC2 role to use the key for Secrets Manager only (tight actions + conditions)
  statement {
    sid = "AllowEc2RoleUseForSecretsManager"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ssogen_ec2.arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]

    # Constrain to Secrets Manager in this account/region
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "ssogen_kms" {
  description         = "KMS for SSH private keys in Secrets Manager"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ssogen_kms_policy.json

  tags = {
    Environment = local.environment
  }
}

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
# checkov:skip=CKV2_AWS_57: SSH keypair rotation is handled via a planned key replacement process; moving to SSM Session Manager (no SSH keys) shortly.
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

