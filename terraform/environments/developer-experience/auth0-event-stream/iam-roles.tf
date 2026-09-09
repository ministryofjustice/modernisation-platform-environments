module "firehose_iam_role" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=ba3fd6ded6911e0454092147fe3704171cc05e00" # v6.8.1

  name            = "${local.component_name}-firehose"
  use_name_prefix = false

  trust_policy_permissions = {
    Firehose = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["firehose.amazonaws.com"]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    S3BucketAccess = {
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
      ]
      resources = [module.s3_bucket[0].s3_bucket_arn]
    }
    S3ObjectAccess = {
      effect = "Allow"
      actions = [
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
      ]
      resources = ["${module.s3_bucket[0].s3_bucket_arn}/*"]
    }
    KMSAccess = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey",
      ]
      resources = [module.destination_kms_key[0].key_arn]
    }
    CloudWatchLogsGroupAccess = {
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
      ]
      resources = [module.firehose_cloudwatch_log_group[0].cloudwatch_log_group_arn]
    }
    CloudWatchLogsAccess = {
      effect    = "Allow"
      actions   = ["logs:PutLogEvents"]
      resources = [aws_cloudwatch_log_stream.firehose[0].arn]
    }
  }
}

module "cross_region_iam_role" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=ba3fd6ded6911e0454092147fe3704171cc05e00" # v6.8.1

  name            = "${local.component_name}-eventbridge-cross-region"
  use_name_prefix = false

  trust_policy_permissions = {
    EventBridge = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    EventBridge = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [module.destination_eventbridge[0].eventbridge_bus_arn]
    }
  }
}
