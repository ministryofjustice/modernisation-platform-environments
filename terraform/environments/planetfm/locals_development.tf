# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    # baseline_s3_buckets = {
    #   public-lb-logs-bucket = {
    #     bucket_policy_v2 = [
    #       {
    #         effect = "Allow"
    #         actions = [
    #           "s3:PutObject",
    #         ]
    #         principals = {
    #           identifiers = ["arn:aws:iam::652711504416:root"]
    #           type        = "AWS"
    #         }
    #       },
    #       {
    #         effect = "Allow"
    #         actions = [
    #           "s3:PutObject"
    #         ]
    #         principals = {
    #           identifiers = ["delivery.logs.amazonaws.com"]
    #           type        = "Service"
    #         }

    #         conditions = [
    #           {
    #             test     = "StringEquals"
    #             variable = "s3:x-amz-acl"
    #             values   = ["bucket-owner-full-control"]
    #           }
    #         ]
    #       },
    #       {
    #         effect = "Allow"
    #         actions = [
    #           "s3:GetBucketAcl"
    #         ]
    #         principals = {
    #           identifiers = ["delivery.logs.amazonaws.com"]
    #           type        = "Service"
    #         }
    #       }
    #     ]
    #     iam_policies = module.baseline_presets.s3_iam_policies
    #   }
    #   network-lb-logs-bucket = {
    #     sse_algorithm = "AES256"
    #     bucket_policy_v2 = [
    #       {
    #         effect = "Allow"
    #         actions = [
    #           "s3:PutObject"
    #         ]
    #         principals = {
    #           identifiers = ["delivery.logs.amazonaws.com"]
    #           type        = "Service"
    #         }
    #         conditions = [
    #           {
    #             test     = "StringEquals"
    #             variable = "s3:x-amz-acl"
    #             values   = ["bucket-owner-full-control"]
    #           },
    #           {
    #             test     = "StringEquals"
    #             variable = "aws:SourceAccount"
    #             values   = [module.environment.account_id]
    #           },
    #           {
    #             test     = "ArnLike"
    #             variable = "aws:SourceArn"
    #             values   = ["arn:aws:logs:${module.environment.region}:${module.environment.account_id}:*"]
    #           }
    #         ]
    #       },
    #       {
    #         effect = "Allow"
    #         actions = [
    #           "s3:GetBucketAcl"
    #         ]
    #         principals = {
    #           identifiers = ["delivery.logs.amazonaws.com"]
    #           type        = "Service"
    #         }
    #         conditions = [
    #           {
    #             test     = "StringEquals"
    #             variable = "aws:SourceAccount"
    #             values   = [module.environment.account_id]
    #           },
    #           {
    #             test     = "ArnLike"
    #             variable = "aws:SourceArn"
    #             values   = ["arn:aws:logs:${module.environment.region}:${module.environment.account_id}:*"]
    #           }
    #         ]
    #       }
    #     ]
    #     iam_policies = module.baseline_presets.s3_iam_policies
    #   }
    # }
  }
}

