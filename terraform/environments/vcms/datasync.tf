# intermediate bucket for EFS migration
module "s3_bucket_efs_migration" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v9.0.0"
  bucket_name         = "vcms-${local.environment}-efs-migration-landing"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  sse_algorithm       = "AES256"

  bucket_policy_v2 = [
    {
      effect  = "Allow"
      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts"
      ]
      resources = [
        "arn:aws:s3:::vcms-${local.environment}-efs-migration-landing",
        "arn:aws:s3:::vcms-${local.environment}-efs-migration-landing/*"
      ]
      principals = {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${aws_ssm_parameter.legacy_account_id.value}:role/vcms-legacy-datasync-role",
          aws_iam_role.datasync_import_role.arn
        ]
      }
    }
  ]

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}


resource "aws_datasync_location_s3" "migration_s3_source" {
  s3_bucket_arn = module.s3_bucket_efs_migration.bucket.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_import_role.arn
  }

  s3_storage_class = "STANDARD"

  depends_on = [
    aws_iam_role_policy.datasync_import_permissions,
    module.s3_bucket_efs_migration
  ]
}

resource "aws_datasync_location_efs" "vcms_efs_target" {
  efs_file_system_arn = aws_efs_file_system.vcms.arn
  subdirectory        = "/"

  ec2_config {
    security_group_arns = [aws_security_group.efs.arn]
    subnet_arn          = "arn:aws:ec2:${local.account_info.region}:${local.account_info.id}:subnet/${local.account_config.private_subnet_ids[0]}"
  }
}

resource "aws_datasync_task" "import_s3_to_efs" {
  name                     = "vcms-import-s3-to-efs-${local.environment}"
  source_location_arn      = aws_datasync_location_s3.migration_s3_source.arn
  destination_location_arn = aws_datasync_location_efs.vcms_efs_target.arn
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_import.arn

  options {
    bytes_per_second       = -1
    posix_permissions      = "PRESERVE"
    uid                    = "INT_VALUE"
    gid                    = "INT_VALUE"
    preserve_deleted_files = "PRESERVE"
    verify_mode = "POINT_IN_TIME_CONSISTENT"
  }
}


resource "aws_iam_role" "datasync_import_role" {
  name               = "vcms-datasync-import-role-${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.datasync_assume.json
}


data "aws_iam_policy_document" "datasync_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy" "datasync_import_permissions" {
  name = "vcms-datasync-import-policy"
  role = aws_iam_role.datasync_import_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:GetObject",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          module.s3_bucket_efs_migration.bucket.arn,
          "${module.s3_bucket_efs_migration.bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:DescribeFileSystems"
        ]
        Resource = [aws_efs_file_system.vcms.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AttachNetworkInterface",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.datasync_import.arn}:*"]
      }
    ]
  })
}


resource "aws_cloudwatch_log_group" "datasync_import" {
  name              = "/aws/datasync/vcms-import-s3-to-efs-${local.environment}"
  retention_in_days = 30
  kms_key_id        = local.account_config.kms_keys.general_shared
  tags              = local.tags
}
