data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        var.datadog_integration_external_id
      ]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration" {
  #checkov:skip=CKV_AWS_356: datadog required
  #checkov:skip=CKV_AWS_111: datadog required
  statement {
    actions = [
      "apigateway:GET",
      "autoscaling:Describe*",
      "backup:List*",
      "bcm-data-exports:GetExport",
      "bcm-data-exports:ListExports",
      "budgets:ViewBudget",
      "cassandra:Select",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:LookupEvents",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "codedeploy:BatchGet*",
      "codedeploy:List*",
      "cur:DescribeReportDefinitions",
      "directconnect:Describe*",
      "dynamodb:Describe*",
      "dynamodb:List*",
      "ec2:Describe*",
      "ec2:GetAllowedImagesSettings",
      "ec2:GetEbsDefaultKmsKeyId",
      "ec2:GetInstanceMetadataDefaults",
      "ec2:GetSerialConsoleAccessStatus",
      "ec2:GetSnapshotBlockPublicAccessState",
      "ec2:GetTransitGatewayPrefixListReferences",
      "ec2:SearchTransitGatewayRoutes",
      "ecs:Describe*",
      "ecs:List*",
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeTags",
      "elasticloadbalancing:Describe*",
      "elasticmapreduce:Describe*",
      "elasticmapreduce:List*",
      "es:DescribeElasticsearchDomains",
      "es:ListDomainNames",
      "es:ListTags",
      "events:CreateEventBus",
      "fsx:DescribeFileSystems",
      "fsx:ListTagsForResource",
      "glacier:GetVaultNotifications",
      "glue:ListRegistries",
      "health:DescribeAffectedEntities",
      "health:DescribeEventDetails",
      "health:DescribeEvents",
      "kinesis:Describe*",
      "kinesis:List*",
      "lambda:GetPolicy",
      "lambda:List*",
      "lightsail:GetInstancePortStates",
      "logs:DeleteSubscriptionFilter",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeSubscriptionFilters",
      "logs:FilterLogEvents",
      "logs:PutSubscriptionFilter",
      "logs:TestMetricFilter",
      "oam:ListAttachedLinks",
      "oam:ListSinks",
      "organizations:Describe*",
      "organizations:List*",
      "rds:Describe*",
      "rds:List*",
      "redshift:DescribeClusters",
      "redshift:DescribeLoggingStatus",
      "route53:List*",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketTagging",
      "s3:ListAccessGrants",
      "s3:ListAllMyBuckets",
      "s3:PutBucketNotification",
      "s3express:GetBucketPolicy",
      "s3express:GetEncryptionConfiguration",
      "s3express:ListAllMyDirectoryBuckets",
      "savingsplans:DescribeSavingsPlanRates",
      "savingsplans:DescribeSavingsPlans",
      "secretsmanager:GetResourcePolicy",
      "ses:Get*",
      "sns:GetSubscriptionAttributes",
      "sns:List*",
      "sns:Publish",
      "sqs:ListQueues",
      "states:DescribeStateMachine",
      "states:ListStateMachines",
      "support:DescribeTrustedAdvisor*",
      "support:RefreshTrustedAdvisorCheck",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues",
      "timestream:DescribeEndpoints",
      "timestream:ListTables",
      "waf-regional:GetRule",
      "waf-regional:GetRuleGroup",
      "waf-regional:ListRuleGroups",
      "waf-regional:ListRules",
      "waf:GetRule",
      "waf:GetRuleGroup",
      "waf:ListRuleGroups",
      "waf:ListRules",
      "wafv2:GetIPSet",
      "wafv2:GetLoggingConfiguration",
      "wafv2:GetRegexPatternSet",
      "wafv2:GetRuleGroup",
      "wafv2:ListLoggingConfigurations",
      "xray:BatchGetTraces",
      "xray:GetTraceSummaries"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_aws_integration" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration.json
}

resource "aws_iam_role" "datadog_aws_integration" {
  name               = "DatadogAWSIntegrationRole"
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role.json
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = aws_iam_policy.datadog_aws_integration.arn
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration_security_audit" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_role" "cw_logs_to_firehose" {
  name = "cw-logs-to-firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cw_logs_to_firehose_policy" {
  name = "AllowCWLogsToWriteToFirehose"
  role = aws_iam_role.cw_logs_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = aws_kinesis_firehose_delivery_stream.to_datadog.arn
      }
    ]
  })
}

resource "aws_iam_role" "firehose_to_datadog" {
  name = "firehose_to_datadog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "FirehoseToDatadogPolicy"
  description = "Allows Firehose to send data to Datadog"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ],
        Resource = aws_cloudwatch_log_group.firehose_log_group.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attach" {
  role       = aws_iam_role.firehose_to_datadog.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_kinesis_firehose_delivery_stream" "to_datadog" {
  name        = "cloudwatch-to-datadog"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://http-intake.logs.datadoghq.eu/v1/input/PLACEHOLDER"
    name               = "Datadog"
    access_key         = ""
    buffering_interval = 60
    buffering_size     = 1
    role_arn           = aws_iam_role.firehose_to_datadog.arn

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = "firehose-datadog-http"
    }

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_backup_mode = "AllData"
    s3_configuration {
      role_arn           = aws_iam_role.firehose_to_datadog.arn
      bucket_arn         = aws_s3_bucket.firehose_backup.arn
      buffering_interval = 60
      buffering_size     = 5
      compression_format = "GZIP"
    }
  }

  server_side_encryption {
    enabled = true
    key_arn = aws_kms_key.firehose_backup.arn
  }

  lifecycle {
    ignore_changes = [http_endpoint_configuration[0].url]
  }
}

resource "aws_s3_bucket" "firehose_backup" {
  # checkov:skip=CKV2_AWS_62
  # checkov:skip=CKV_AWS_144
  bucket = "yjaf-${var.environment}-firehose-datadog-backup"
}

resource "aws_s3_bucket_public_access_block" "firehose_backup_block" {
  bucket = aws_s3_bucket.firehose_backup.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "firehose_backup_versioning" {
  bucket = aws_s3_bucket.firehose_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "firehose_backup_lifecycle" {
  bucket = aws_s3_bucket.firehose_backup.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "firehose_backup_logging" {
  bucket = aws_s3_bucket.firehose_backup.id

  target_bucket = "your-logging-bucket-name"
  target_prefix = "firehose-backup-logs/"
}

resource "aws_kms_key" "firehose_backup" {
  description             = "KMS key for encrypting Firehose S3 backup bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# KMS Key Policy (Ensure Firehose can use this key)
resource "aws_kms_key_policy" "firehose_backup_policy" {
  key_id = aws_kms_key.firehose_backup.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowFirehoseServiceAccess",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Resource = aws_kms_key.firehose_backup.arn
      },
      {
        Sid    = "AllowAccountRootUserFullAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = aws_kms_key.firehose_backup.arn
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firehose_backup_encryption" {
  bucket = aws_s3_bucket.firehose_backup.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.firehose_backup.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "yjaf-${var.environment}-firehose-error-logs"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.firehose_backup.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cloudtrail" {
  name            = "firehose-subscription"
  log_group_name  = "cloudtrail"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.to_datadog.arn
  role_arn        = aws_iam_role.cw_logs_to_firehose.arn
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

