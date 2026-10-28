# Copies the Bedrock invocation log records to an HMCTS PlatOps Azure container, so their token
# metrics reporting has the data without anyone there needing AWS access.
#
# DataSync in Enhanced task mode moves data between S3 and Azure Blob with no agent to run, which
# is the only reason this is a managed task rather than a scheduled job pushing with AzCopy. The
# Azure Blob location goes through CloudFormation because the AWS provider still marks agent_arns
# as required on aws_datasync_location_azure_blob, which rules out an agentless location
# (hashicorp/terraform-provider-aws#43066).

locals {
  # Container supplied by PlatOps. Its SAS token lives in Secrets Manager; DataSync reads it from
  # there at run time, so the token is in neither this repo nor the Terraform state.
  bedrock_logs_sync_container = "https://spsaitokenmetrics.blob.core.windows.net/bedrock-claude-v1-token-metrics"
  bedrock_logs_sync_schedule  = "cron(15 * * * ? *)"
  bedrock_logs_sync_secret    = "bedrock-logs-azure-sas"
}

resource "aws_secretsmanager_secret" "bedrock_logs_azure_sas" {
  #checkov:skip=CKV2_AWS_57: "An Azure SAS token is reissued by PlatOps; AWS cannot rotate it"
  #checkov:skip=CKV_AWS_149: "Default Secrets Manager encryption; the token reaches one Azure container"
  for_each    = local.bedrock_log_buckets
  region      = each.key
  name        = local.bedrock_logs_sync_secret
  description = "SAS token for the PlatOps Azure container that invocation logs are copied to"
  tags        = local.tags
}

# The real token is put in out of band, so it passes through neither a plan nor a state file. This
# placeholder only gives the secret a version for DataSync to resolve. See the README.
resource "aws_secretsmanager_secret_version" "bedrock_logs_azure_sas" {
  for_each      = aws_secretsmanager_secret.bedrock_logs_azure_sas
  region        = each.key
  secret_id     = each.value.id
  secret_string = "placeholder"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_iam_policy_document" "bedrock_logs_sync_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "bedrock_logs_sync" {
  name               = "BedrockLogsSync"
  assume_role_policy = data.aws_iam_policy_document.bedrock_logs_sync_assume_role.json
  tags               = local.tags
}

# Read only: the destination is Azure, so nothing is written back to the buckets.
data "aws_iam_policy_document" "bedrock_logs_sync" {
  statement {
    sid       = "ListBuckets"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
    resources = [for bucket in aws_s3_bucket.bedrock_logs : bucket.arn]
  }

  statement {
    sid       = "ReadObjects"
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListMultipartUploadParts"]
    resources = [for bucket in aws_s3_bucket.bedrock_logs : "${bucket.arn}/*"]
  }

  # The buckets are SSE-KMS with a customer-managed key, so object read access is not enough.
  statement {
    sid       = "DecryptObjects"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [for key in aws_kms_key.bedrock_logs : key.arn]
  }

  statement {
    sid       = "ReadSasToken"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [for secret in aws_secretsmanager_secret.bedrock_logs_azure_sas : secret.arn]
  }
}

resource "aws_iam_role_policy" "bedrock_logs_sync" {
  name   = "BedrockLogsSync"
  role   = aws_iam_role.bedrock_logs_sync.id
  policy = data.aws_iam_policy_document.bedrock_logs_sync.json
}

resource "aws_datasync_location_s3" "bedrock_logs" {
  for_each      = aws_s3_bucket.bedrock_logs
  region        = each.key
  s3_bucket_arn = each.value.arn
  subdirectory  = "/invocation-logs"
  tags          = local.tags

  s3_config {
    bucket_access_role_arn = aws_iam_role.bedrock_logs_sync.arn
  }
}

resource "aws_cloudformation_stack" "bedrock_logs_azure_location" {
  for_each = local.bedrock_log_buckets
  region   = each.key
  name     = "bedrock-logs-azure-location"
  tags     = local.tags

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "DataSync location for the PlatOps Azure container, agentless"

    Resources = {
      Location = {
        Type = "AWS::DataSync::LocationAzureBlob"
        Properties = {
          AzureBlobAuthenticationType = "SAS"
          AzureBlobContainerUrl       = local.bedrock_logs_sync_container
          AzureBlobType               = "BLOCK"
          AzureAccessTier             = "HOT"

          # One folder per source region, because the records of both carry the same key layout.
          Subdirectory = "/${each.key}"

          CustomSecretConfig = {
            SecretArn           = aws_secretsmanager_secret.bedrock_logs_azure_sas[each.key].arn
            SecretAccessRoleArn = aws_iam_role.bedrock_logs_sync.arn
          }
        }
      }
    }

    Outputs = {
      LocationArn = {
        Value = { "Fn::GetAtt" = ["Location", "LocationArn"] }
      }
    }
  })

  depends_on = [
    aws_iam_role_policy.bedrock_logs_sync,
    aws_secretsmanager_secret_version.bedrock_logs_azure_sas,
  ]
}

resource "aws_cloudwatch_log_group" "bedrock_logs_sync" {
  #checkov:skip=CKV_AWS_158: "Transfer logs carry object keys and counts, no record content"
  for_each          = local.bedrock_log_buckets
  region            = each.key
  name              = "/aws/datasync/bedrock-logs-sync"
  retention_in_days = 30
  tags              = local.tags
}

data "aws_iam_policy_document" "bedrock_logs_sync_logs" {
  for_each = aws_cloudwatch_log_group.bedrock_logs_sync

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${each.value.arn}:*"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "bedrock_logs_sync" {
  for_each        = aws_cloudwatch_log_group.bedrock_logs_sync
  region          = each.key
  policy_name     = "BedrockLogsSyncDelivery"
  policy_document = data.aws_iam_policy_document.bedrock_logs_sync_logs[each.key].json
}

resource "aws_datasync_task" "bedrock_logs" {
  for_each                 = local.bedrock_log_buckets
  region                   = each.key
  name                     = "bedrock-logs-to-azure-${each.key}"
  source_location_arn      = aws_datasync_location_s3.bedrock_logs[each.key].arn
  destination_location_arn = aws_cloudformation_stack.bedrock_logs_azure_location[each.key].outputs["LocationArn"]
  task_mode                = "ENHANCED"
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.bedrock_logs_sync[each.key].arn
  tags                     = local.tags

  schedule {
    schedule_expression = local.bedrock_logs_sync_schedule
  }

  # Request and response bodies over 100KB were written to a data/ folder alongside the records
  # until text delivery was turned off. Those objects are prompts and source code rather than
  # token metrics, and they stay in the bucket until the 90 day lifecycle reaches them.
  excludes {
    filter_type = "SIMPLE_PATTERN"
    value       = "*/data"
  }

  options {
    # Azure Blob does not take object tags, and an Enhanced mode task fails outright rather than
    # per-object if it is asked to preserve them.
    object_tags = "NONE"

    # Neither end is a filesystem, so there is no ownership or permission to carry over.
    atime             = "NONE"
    mtime             = "NONE"
    uid               = "NONE"
    gid               = "NONE"
    posix_permissions = "NONE"

    # Our own lifecycle expires records after 90 days; PRESERVE stops that pruning their copy.
    preserve_deleted_files = "PRESERVE"

    transfer_mode = "CHANGED"
    verify_mode   = "ONLY_FILES_TRANSFERRED"
    log_level     = "TRANSFER"
  }
}
