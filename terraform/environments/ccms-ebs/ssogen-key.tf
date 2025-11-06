# checkov:skip=CKV_AWS_356: KMS key policies require Resource="*"; constrained via principals/conditions
# checkov:skip=CKV_AWS_109: Root admin stanza retained; functional use is tightly scoped
data "aws_iam_policy_document" "ssogen_kms_policy" {
  statement {
    sid = "AllowRootAccountAdmin"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid = "AllowUseForSecretsManagerInThisAccount"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
      , "kms:DescribeKey"
    ]
    resources = ["*"]

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
  count               = local.is_development ? 1 : 0
  description         = "KMS for SSH private keys in Secrets Manager"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ssogen_kms_policy.json
  tags                = { Environment = local.environment }
}

# Generate SSH key pair
resource "tls_private_key" "ssogen" {
  count     = local.is_development ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssogen" {
  count      = local.is_development ? 1 : 0
  key_name   = "ssogen_key_name"
  public_key = tls_private_key.ssogen[0].public_key_openssh
  tags       = { Name = "ssogen-key", Environment = local.environment }

  lifecycle {
    ignore_changes = [ public_key ]
  }

}

resource "aws_secretsmanager_secret" "ssogen_privkey" {
  count                   = local.is_development ? 1 : 0
  name                    = "ssh/${local.environment}/ssogen/private-key"
  kms_key_id              = aws_kms_key.ssogen_kms[0].arn
  recovery_window_in_days = 7
  tags                    = { Environment = local.environment, Purpose = "ec2-ssh" }

}

resource "aws_secretsmanager_secret_version" "ssogen_privkey_v1" {
  count     = local.is_development ? 1 : 0
  secret_id = aws_secretsmanager_secret.ssogen_privkey[0].id
  secret_string = jsonencode({
    private_key_pem = tls_private_key.ssogen[0].private_key_pem
    public_key      = tls_private_key.ssogen[0].public_key_openssh
    fingerprint_md5 = tls_private_key.ssogen[0].public_key_fingerprint_md5
    key_type        = "rsa"
    key_name        = aws_key_pair.ssogen[0].key_name
    environment     = local.environment
    region          = data.aws_region.current.name
    created_at_utc  = timestamp()
  })

  lifecycle {
    ignore_changes = [ secret_string ]
  }
}
