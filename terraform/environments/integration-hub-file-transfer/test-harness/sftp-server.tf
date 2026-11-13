data "aws_kms_alias" "sftp_credentials" {
  count = local.create_test_harness ? 1 : 0

  name = "alias/${local.application_name}-push-to-sftp-credentials"
}

data "aws_iam_policy_document" "sftp_server" {
  count = local.create_test_harness ? 1 : 0

  statement {
    sid     = "ReadServerCredentials"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      module.secrets_sftp_host_key.secret_arn,
      local.sftp_client_public_key_secret_arn,
    ]
  }

  statement {
    sid       = "DecryptServerCredentials"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.secrets[0].target_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "DecryptSftpClientPublicKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.sftp_credentials[0].target_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:SecretARN"
      values   = [local.sftp_client_public_key_secret_arn]
    }
  }

  statement {
    sid       = "ListReadBackBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3_sftp_readback.s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.sftp_readback_prefix}*"]
    }
  }

  statement {
    sid       = "WriteReadBackCopies"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.s3_sftp_readback.s3_bucket_arn}/${local.sftp_readback_prefix}*"]
  }
}

module "iam_policy_sftp_server" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  create      = local.create_test_harness
  name        = local.sftp_server_name
  description = "Read the test SFTP server credentials and copy deliveries to the read-back bucket"
  policy      = local.create_test_harness ? data.aws_iam_policy_document.sftp_server[0].json : null

  tags = local.tags
}

module "sftp_server" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.1"

  create = local.create_test_harness

  name                   = local.sftp_server_name
  instance_type          = "t3.micro"
  subnet_id              = local.sftp_subnet_id
  private_ip             = local.sftp_private_ip
  vpc_security_group_ids = [module.security_group_sftp_server.id]
  ignore_ami_changes     = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device = {
    encrypted = true
    type      = "gp3"
    size      = 8
  }

  create_security_group       = false
  create_iam_instance_profile = true
  iam_role_name               = local.sftp_server_name
  iam_role_use_name_prefix    = false
  iam_role_description        = "Test SFTP server for the Integration Hub push-to-sftp tests"
  iam_role_policies           = { sftp_server = module.iam_policy_sftp_server.arn }
  user_data_replace_on_change = true
  user_data_base64            = local.create_test_harness ? base64encode(local.sftp_user_data) : null

  tags = local.tags
}
