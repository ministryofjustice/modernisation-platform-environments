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

###
###   aws_iam_session_context
###
data "aws_iam_session_context" "whoami" {
  provider = aws.oidc-session
  arn      = data.aws_caller_identity.oidc_session.arn
}

###
###   aws_caller_identity
###
data "aws_caller_identity" "current" {}
data "aws_caller_identity" "oidc_session" { provider = aws.oidc-session }
data "aws_caller_identity" "modernisation_platform" { provider = aws.modernisation-platform }

###
###   aws_organizations_organization
###
# This data sources allows us to get the Modernisation Platform account information for use elsewhere (when we want to assume a role in the MP, for instance)
data "aws_organizations_organization" "root_account" {}

###
###   aws_vpc
###
data "aws_vpc" "shared" { tags = { Name = "${local.business_unit}-${local.environment}" } }

###
###   aws_region
###
data "aws_region" "current" {}

###
###   aws_subnets
###
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${local.business_unit}-${local.environment}-${local.subnet_set}-private-${local.region}*"
  }
}
data "aws_subnets" "shared-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${local.business_unit}-${local.environment}-${local.networking_set}-public*"
  }
}
data "aws_subnets" "shared-data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${local.business_unit}-${local.environment}-${local.networking_set}-data*"
  }
}


###
###   aws_subnet
###
data "aws_subnet" "data_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.business_unit}-${local.environment}-${local.networking_set}-data-${data.aws_region.current.name}a"
  }
}
data "aws_subnet" "data_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.business_unit}-${local.environment}-${local.networking_set}-data-${data.aws_region.current.name}b"
  }
}
data "aws_subnet" "data_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.business_unit}-${local.environment}-${local.networking_set}-data-${data.aws_region.current.name}c"
  }
}
data "aws_subnet" "private_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.business_unit}-${local.environment}-${local.networking_set}-private-${data.aws_region.current.name}a"
  }
}
data "aws_subnet" "private_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.business_unit}-${local.environment}-${local.networking_set}-private-${data.aws_region.current.name}b"
  }
}
data "aws_subnet" "private_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${local.business_unit}-${local.environment}-${local.networking_set}-private-${data.aws_region.current.name}c"
  }
}
data "aws_subnet" "public_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${local.business_unit}-${local.environment}-${local.networking_set}-public-${data.aws_region.current.name}a"
  }
}
data "aws_subnet" "public_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${local.business_unit}-${local.environment}-${local.networking_set}-public-${data.aws_region.current.name}b"
  }
}
data "aws_subnet" "public_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${local.business_unit}-${local.environment}-${local.networking_set}-public-${data.aws_region.current.name}c"
  }
}

###
###   aws_route53_zone
###
data "aws_route53_zone" "external" {
  provider     = aws.core-vpc
  name         = "${local.business_unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}
data "aws_route53_zone" "inner" {
  provider     = aws.core-vpc
  name         = "${local.business_unit}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}
data "aws_route53_zone" "network-services" {
  provider     = aws.core-network-services
  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

###
###   terraform_remote_state
###
# State for core-network-services resource information
data "terraform_remote_state" "core_network_services" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/accounts/core-network-services/core-network-services-production/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
}

###
###   aws_ssm_parameter
###
data "aws_ssm_parameter" "modernisation_platform_account_id" {
  name = "modernisation_platform_account_id"
}

###
###   aws_secretsmanager_secret
###
data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}

###
###   aws_secretsmanager_secret_version
###
# This secret stores account IDs for the Modernisation Platform sub-accounts
data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

###
###   aws_kms_key
###
# Shared KMS keys (per business unit)
data "aws_kms_key" "general_shared" { key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/general-${local.business_unit}" }
data "aws_kms_key" "ebs_shared" { key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/ebs-${local.business_unit}" }
data "aws_kms_key" "rds_shared" { key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/rds-${local.business_unit}" }

###
###   aws_iam_policy_document
###
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
    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
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
}
# combine ec2-common policy documents
data "aws_iam_policy_document" "ec2_common_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.ssm_custom.json,
    data.aws_iam_policy_document.s3_bucket_access.json,
    data.aws_iam_policy_document.cloud_watch_custom.json
  ]
}
data "aws_iam_policy_document" "cross-account-s3" {
  statement {
    sid = "cross-account-s3-access-for-image-builder"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = ["${module.image-builder-bucket.bucket.arn}/*",
    module.image-builder-bucket.bucket.arn, ]
    principals {
      type = "AWS"
      identifiers = sort([ # sort to avoid plan changes
        "arn:aws:iam::${local.account_id}:root",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ])
    }
  }
}
# data "aws_iam_policy_document" "ssm_ec2_start_stop_kms" {
#   statement {
#     sid    = "manageSharedAMIsEncryptedEBSVolumes"
#     effect = "Allow"
#     #tfsec:ignore:aws-iam-no-policy-wildcards
#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:ReEncrypt*",
#       "kms:ReEncryptFrom",
#       "kms:GenerateDataKey*",
#       "kms:DescribeKey",
#       "kms:CreateGrant",
#       "kms:ListGrants",
#       "kms:RevokeGrant"
#     ]
#     # we have a legacy CMK that's used in production that will be retired but in the meantime requires permissions
#     resources = [local.environment == "test" ? aws_kms_key.oasys-cmk[0].arn : data.aws_kms_key.oasys_key.arn, data.aws_kms_key.hmpps_key.arn]
#   }
# }

# data "aws_iam_policy_document" "cloud-platform-monitoring-assume-role" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::754256621582:root"]  # cloud-platform-aws account
#     }
#   }
# }

# data "aws_iam_policy_document" "cloudwatch_datasource" {
#   statement {
#     sid    = "AllowReadingMetricsFromCloudWatch"
#     effect = "Allow"
#     actions = [
#       "cloudwatch:DescribeAlarmsForMetric",
#       "cloudwatch:DescribeAlarmHistory",
#       "cloudwatch:DescribeAlarms",
#       "cloudwatch:ListMetrics",
#       "cloudwatch:GetMetricData",
#       "cloudwatch:GetInsightRuleReport"
#     ]
#     #tfsec:ignore:aws-iam-no-policy-wildcards
#     resources = ["*"]
#   }
#   statement {
#     sid    = "AllowReadingLogsFromCloudWatch"
#     effect = "Allow"
#     actions = [
#       "logs:DescribeLogGroups",
#       "logs:GetLogGroupFields",
#       "logs:StartQuery",
#       "logs:StopQuery",
#       "logs:GetQueryResults",
#       "logs:GetLogEvents"
#     ]
#     #tfsec:ignore:aws-iam-no-policy-wildcards
#     resources = ["*"]
#   }
#   statement {
#     sid    = "AllowReadingTagsInstancesRegionsFromEC2"
#     effect = "Allow"
#     actions = [
#       "ec2:DescribeTags",
#       "ec2:DescribeInstances",
#       "ec2:DescribeRegions"
#     ]
#     resources = ["*"]
#   }
#   statement {
#     sid    = "AllowReadingResourcesForTags"
#     effect = "Allow"
#     actions = [
#       "tag:GetResources"
#     ]
#     resources = ["*"]
#   }
# }

###
###   http
###
# Get the environments file from the main repository
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}