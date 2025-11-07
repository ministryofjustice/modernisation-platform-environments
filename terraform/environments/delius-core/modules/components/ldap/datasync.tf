resource "aws_datasync_location_efs" "destination" {
  ec2_config {
    # security_group_arns = [aws_security_group.ldap_efs.arn]
    security_group_arns = [module.efs.sg_arn]
    subnet_arn          = "arn:aws:ec2:${var.account_info.region}:${var.account_info.id}:subnet/${var.account_config.private_subnet_ids[0]}"
  }
  efs_file_system_arn = module.efs.fs_arn
}

resource "aws_datasync_location_efs" "source" {
  ec2_config {
    # security_group_arns = [aws_security_group.ldap_efs.arn]
    security_group_arns = [module.efs.sg_arn]
    subnet_arn          = "arn:aws:ec2:${var.account_info.region}:${var.account_info.id}:subnet/${var.account_config.private_subnet_ids[0]}"
  }
  # efs_file_system_arn = aws_efs_file_system.ldap.arn
  efs_file_system_arn = module.efs.fs_arn
}

resource "aws_datasync_task" "ldap_refresh_task" {
  destination_location_arn = aws_datasync_location_efs.destination.arn
  source_location_arn      = aws_datasync_location_efs.source.arn

  name = "ldap-datasync-task-push-from-${var.env_name}"
}

# iam role for aws backup to assume in the data-refresh pipeline using the aws backup start-restore-job cmd
resource "aws_iam_role" "ldap_datasync_role" {
  name               = "ldap-data-refresh-role-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.ldap_datasync_role_assume.json
}

resource "aws_iam_role_policy" "ldap_refresh_access" {
  policy = data.aws_iam_policy_document.ldap_datasync_role_access.json
  role   = aws_iam_role.ldap_datasync_role.name
}

data "aws_iam_policy_document" "ldap_datasync_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com", "backup.amazonaws.com"]
    }
  }
}

#trivy:ignore:AVD-AWS-0345
data "aws_iam_policy_document" "ldap_datasync_role_access" {
  #checkov:skip=CKV_AWS_109
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_356
  statement {
    effect = "Allow"
    actions = [
      "backup:*",
      "datasync:*",
      "elasticfilesystem:*",
      "ec2:DescribeInstances",
      "ec2:CreateNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:ListGrants",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:CreateGrant",
      "kms:ReEncryptTo",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKeyWithoutPlaintext"
    ]
    resources = [var.account_config.kms_keys.general_shared]
  }
  statement {
    sid     = "allowAccessForDataSync"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::*-ldap-data-refresh-incoming",
      "arn:aws:s3:::*-ldap-data-refresh-incoming/*",
    ]
  }
}

locals {
  delius_core_accounts = { for k, v in nonsensitive(var.platform_vars.environment_management.account_ids) : k => v if startswith(k, "delius-core") }
  ldap_refresh_bucket_policies = [for account_name, account_id in local.delius_core_accounts :
    {
      effect  = "Allow"
      actions = ["s3:*"]
      resources = [
        module.s3_bucket_ldap_data_refresh.bucket.arn,
        "${module.s3_bucket_ldap_data_refresh.bucket.arn}/*",
      ]
      principals = {
        type        = "AWS"
        identifiers = ["*"]
      }
      conditions = [
        {
          test     = "ArnLike"
          values   = ["arn:aws:iam::${account_id}:role/ldap-data-refresh-role-*"]
          variable = "aws:PrincipalARN"
        }
      ]
    }
  ]

}


module "s3_bucket_ldap_data_refresh" {
  #checkov:skip=CKV_TF_1
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"
  bucket_name         = "${var.env_name}-ldap-data-refresh-incoming"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared
  bucket_policy_v2    = local.ldap_refresh_bucket_policies

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  tags = var.tags
}