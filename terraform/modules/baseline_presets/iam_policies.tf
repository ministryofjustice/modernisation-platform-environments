locals {

  iam_policies_filter = flatten([
    var.options.enable_business_unit_kms_cmks ? ["BusinessUnitKmsCmkPolicy"] : [],
    var.options.enable_image_builder ? ["ImageBuilderLaunchTemplatePolicy"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["CloudWatchAgentServerReducedPolicy"] : []
  ])

  iam_policies = {

    ImageBuilderLaunchTemplatePolicy = {
      description = "Policy allowing access to image builder launch templates"
      statements = [{
        effect = "Allow"
        actions = [
          "ec2:CreateLaunchTemplateVersion",
          "ec2:ModifyLaunchTemplate"
        ]
        resources = ["*"]
        conditions = [{
          test     = "StringEquals"
          variable = "aws:ResourceTag/CreatedBy"
          values   = ["EC2 Image Builder"]
        }]
        }, {
        effect = "Allow"
        actions = [
          "DescribeLaunchTemplates"
        ]
        resources = ["arn:aws:ec2:*:*:launch-template/*"]
        conditions = [{
          test     = "StringEquals"
          variable = "aws:ResourceTag/CreatedBy"
          values   = ["EC2 Image Builder"]
        }]
      }]
    }

    BusinessUnitKmsCmkPolicy = {
      description = "Policy allowing access to business unit wide customer managed keys"
      statements = [{
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
          var.environment.kms_keys["ebs"].arn,
          var.environment.kms_keys["general"].arn
        ]
      }]
    }

    CloudWatchAgentServerReducedPolicy = {
      description = "Same as CloudWatchAgentServerReducedPolicy but with CreateLogGroup permission removed to ensure groups are created in code"
      statements = [{
        effect = "Allow"
        actions = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        resources = ["*"]
        }, {
        effect = "Deny"
        actions = [
          "logs:CreateLogGroup"
        ]
        resources = ["*"]
        }, {
        effect = "Allow"
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        resources = ["arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"]
      }]
    }
  }

}
