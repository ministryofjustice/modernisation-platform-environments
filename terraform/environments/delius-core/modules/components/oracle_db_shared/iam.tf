##############################################
# IAM Instance Profile
##############################################

# Pre-reqs - IAM role, attachment for SSM usage and instance profile
data "aws_iam_policy_document" "db_ec2_instance_iam_assume_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "core_shared_services_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::mod-platform-image-artefact-bucket20230203091453221500000001/*",
      "arn:aws:s3:::mod-platform-image-artefact-bucket20230203091453221500000001"
    ]
  }
}

data "aws_iam_policy_document" "ec2_access_for_ansible" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_access_to_ssm_parameter_store" {
  #checkov:skip=CKV_AWS_111 "ignore"
  #checkov:skip=CKV_AWS_356 "ignore"
  statement {
    sid    = "AllowAccessToSsmParameterStore"
    effect = "Allow"
    actions = [
      "ssm:PutParameter"
    ]
    resources = ["*"]
  }
}

# Policy document for both Oracle Database and Probation Integration secret
data "aws_iam_policy_document" "db_access_to_secrets_manager" {
  statement {
    sid = "DbAccessToSecretsManager"
    actions = [
      "secretsmanager:Describe*",
      "secretsmanager:Get*",
      "secretsmanager:ListSecret*",
      "secretsmanager:Put*",
      "secretsmanager:RestoreSecret",
      "secretsmanager:Update*"
    ]
    effect = "Allow"
    resources = concat(
      [aws_secretsmanager_secret.database_dba_passwords.arn, aws_secretsmanager_secret.database_application_passwords.arn],
    length(aws_secretsmanager_secret.probation_integration_passwords) > 0 ? [aws_secretsmanager_secret.probation_integration_passwords[0].arn] : [])
  }
}

data "aws_iam_policy_document" "instance_ssm" {
  #checkov:skip=CKV_AWS_108 "ignore"
  #checkov:skip=CKV_AWS_111 "ignore"
  #checkov:skip=CKV_AWS_356 "ignore"
  statement {
    sid    = "SSMManagedSSM"
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssm:GetParameter*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "SSMManagedSSMMessages"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SSMManagedEC2Messages"
    effect = "Allow"
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = ["*"]
  }
}

#trivy:ignore:AVD-AWS-0345
data "aws_iam_policy_document" "cert_export" {
  #checkov:skip=CKV_AWS_108 "ignore"
  #checkov:skip=CKV_AWS_111 "ignore"
  #checkov:skip=CKV_AWS_356 "ignore"
  statement {
    sid    = "ExportCert"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ExportCertificate",
      "acm:ListCertificates"
    ]
    resources = ["*"]
  }
}

#trivy:ignore:AVD-AWS-0345
data "aws_iam_policy_document" "combined_instance_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.core_shared_services_bucket_access.json,
    data.aws_iam_policy_document.allow_access_to_ssm_parameter_store.json,
    data.aws_iam_policy_document.ec2_access_for_ansible.json,
    data.aws_iam_policy_document.db_access_to_secrets_manager.json,
    # data.aws_iam_policy_document.oracledb_backup_bucket_access.json,
    data.aws_iam_policy_document.combined.json,
    data.aws_iam_policy_document.db_ssh_keys_s3_policy_document.json,
    data.aws_iam_policy_document.instance_ssm.json,
    data.aws_iam_policy_document.oracle_ec2_snapshot_backup_role_policy_document.json,
    data.aws_iam_policy_document.cert_export.json
  ]
}

resource "aws_iam_policy" "combined_instance_policy" {
  name   = "${var.account_info.application_name}-${var.env_name}-oracle-${var.db_suffix}-combined-instance-policy"
  policy = data.aws_iam_policy_document.combined_instance_policy.json
}

# AWS Backup Role
resource "aws_iam_role" "aws_backup_default_service_role" {
  count = var.create_backup_role ? 1 : 0
  name  = "AWSBackupDefaultServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

data "aws_iam_policy_document" "business_unit_kms_key_access" {
  count = var.create_backup_role ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      var.account_config.kms_keys.general_shared
    ]
  }
}

resource "aws_iam_policy" "business_unit_kms_key_access" {
  count  = var.create_backup_role ? 1 : 0
  name   = "${var.env_name}-${var.db_suffix}-business-unit-kms-key-access-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access[0].json
}

resource "aws_iam_role_policy_attachment" "backup_service_kms_policy_attachment" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.aws_backup_default_service_role[0].name
  policy_arn = aws_iam_policy.business_unit_kms_key_access[0].arn
}