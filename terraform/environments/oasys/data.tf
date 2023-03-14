# There are so many data resources that having a structure is necessary to avoid duplication
# Hoping to move data into modules as much as possible to simplify
# structure:
#   aws_iam_session_context
#   aws_caller_identity
#   aws_organizations_organization
#   aws_vpc
#   aws_region
#   aws_subnets
#   aws_subnet
#   aws_route53_zone
#   terraform_remote_state
#   aws_ssm_parameter
#   aws_secretsmanager_secret
#   aws_secretsmanager_secret_version
#   aws_kms_key
#   aws_iam_policy_document
#   http

# shared CMK used to create AMIs in the MP shared services account
data "aws_kms_key" "ebs_hmpps" { key_id = "arn:aws:kms:${local.region}:${local.environment_management.account_ids["core-shared-services-production"]}:alias/ebs-${local.business_unit}" }
# data "aws_kms_key" "rds_shared" { key_id = "arn:aws:kms:${local.region}:${local.environment_management.account_ids["core-shared-services-production"]}:alias/rds-${local.business_unit}" }
# data "aws_kms_key" "oasys_key" { key_id = "arn:aws:kms:${local.region}:${local.environment_management.account_ids["oasys-test"]}:alias/oasys-image-builder" }


###
###   aws_iam_policy_document
###
# create policy document for access to s3 artefact bucket
data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    sid    = "AllowOracleSecureWebListBucketandGetLocation"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::*"]
  }
  statement {
    sid    = "AccessToInstallationArtefactBucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [module.s3-bucket.bucket.arn,
    "${module.s3-bucket.bucket.arn}/*"]
  }

  # allow access to ec2-image-builder-oasys buckets in all accounts
  statement {
    sid    = "AccessToImageBuilderBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::ec2-image-builder-oasys*",
      "arn:aws:s3:::ec2-image-builder-oasys*/*"
    ]
  }
}
# custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
data "aws_iam_policy_document" "ssm_custom" {
  statement {
    sid    = "CustomSsmPolicy"
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:DescribeDocument",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:GetManifest",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    # skiping these as policy is a scoped down version of Amazon provided AmazonSSMManagedInstanceCore managed policy.  Permissions required for SSM function

    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
}
# custom policy document for cloudwatch agent, based on CloudWatchAgentServerPolicy but removed CreateLogGroup permission to enforce all log groups in code
data "aws_iam_policy_document" "cloud_watch_custom" {
  statement {
    sid    = "CloudWatchAgentServerPolicy"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream"
    ]
    # skiping these as policy is a scoped down version of Amazon provided CloudWatchAgentServerPolicy managed policy
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  }
  statement {
    sid    = "DenyCreateLogGroups"
    effect = "Deny"
    actions = [
      # Letting instances create log groups makes it difficult to delete them later
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AccessCloudWatchConfigParameter"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [aws_ssm_parameter.cloud_watch_config_linux.arn]
  }
}

data "aws_iam_policy_document" "ec2_describe" {
  statement {
    sid    = "AllowApplicationInsights"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances"
    ]
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"] #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  }
}

data "aws_iam_policy_document" "application_insights" {
  statement {
    sid    = "AllowApplicationInsights"
    effect = "Allow"
    actions = [
      "applicationinsights:*",
      "iam:CreateServiceLinkedRole",
      "iam:ListRoles",
      "resource-groups:ListGroups",
      "resource-groups:CreateGroups",
      "resource-groups:UpdateGroup"
    ]
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"] #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  }
}
# combine ec2-common policy documents
data "aws_iam_policy_document" "ec2_common_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.ssm_custom.json,
    data.aws_iam_policy_document.s3_bucket_access.json,
    data.aws_iam_policy_document.cloud_watch_custom.json,
    data.aws_iam_policy_document.ec2_describe.json
  ]
}
data "aws_iam_policy_document" "user-s3-access" {
  statement {
    sid = "user-s3-access"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = ["${module.s3-bucket.bucket.arn}/*",
    module.s3-bucket.bucket.arn, ]
    principals {
      type = "AWS"
      identifiers = sort([ # sort to avoid plan changes
        "arn:aws:iam::${local.account_id}:root",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ])
    }
  }
}
data "aws_iam_policy_document" "ssm_ec2_start_stop_kms" {
  statement {
    sid    = "manageSharedAMIsEncryptedEBSVolumes"
    effect = "Allow"
    #tfsec:ignore:aws-iam-no-policy-wildcards
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    # we have a legacy CMK that's used in production that will be retired but in the meantime requires permissions
    resources = [data.aws_kms_key.ebs_hmpps.arn]
  }

  statement {
    sid    = "modifyAautoscalingGroupProcesses"
    effect = "Allow"

    actions = [
      "autoscaling:SuspendProcesses",
      "autoscaling:ResumeProcesses",
      "autoscaling:DescribeAutoScalingGroups",
    ]
    #this role manages all the autoscaling groups in an account
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
}

data "aws_iam_policy_document" "cloud-platform-monitoring-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754256621582:root"] # cloud-platform-aws account
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_datasource" {
  statement {
    sid    = "AllowReadingMetricsFromCloudWatch"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingLogsFromCloudWatch"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogEvents"
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingTagsInstancesRegionsFromEC2"
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadingResourcesForTags"
    effect = "Allow"
    actions = [
      "tag:GetResources"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "image-builder-distro-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"]
    }
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards needed to look up launch template ids from another account
data "aws_iam_policy_document" "image-builder-launch-template-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeLaunchTemplates"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplateVersion",
      "ec2:ModifyLaunchTemplate",
      "ec2:CreateTags"
    ]
    # coalescelist as there are no weblogics in prod at the moment and empty resource is not acceptable
    # resources = coalescelist([for item in module.weblogic : item.launch_template_arn], ["arn:aws:ec2:${local.region}:${data.aws_caller_identity.current.id}:launch-template/dummy"])
    resources = ["arn:aws:ec2:${local.region}:${data.aws_caller_identity.current.id}:launch-template/*"]
  }
}

data "aws_iam_policy_document" "image-builder-distro-kms-policy" {
  statement {
    effect = "Allow"
    #tfsec:ignore:aws-iam-no-policy-wildcards
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    # we use the same AMIs in test and production, which are encrypted with a single key that only exists in test, hence the below
    resources = [data.aws_kms_key.ebs_hmpps.arn]
  }
}

data "aws_iam_policy_document" "image-builder-combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.image-builder-distro-kms-policy.json,
    data.aws_iam_policy_document.image-builder-launch-template-policy.json
  ]
}

data "aws_iam_policy_document" "mod-platform-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.modernisation_platform.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "launch-template-reader-policy-doc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }
}
