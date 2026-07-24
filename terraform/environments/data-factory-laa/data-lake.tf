locals {
  name      = "laa-data-factory"
  databases = ["raw", "processedraw", "staging", "intermediate", "datamarts", "derived"]
  environments = {
    development = {
      lakeformation_admins = [
        "arn:aws:iam::307869868585:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-sandbox_c38cf78de39ef4d0",
        "arn:aws:iam::307869868585:role/MemberInfrastructureAccess",
        "arn:aws:iam::307869868585:role/github-actions-apply"
      ]
      lakeformation_read_only_admins = [
        "arn:aws:iam::307869868585:role/github-actions-plan"
      ]
    }
    test = {
      lakeformation_admins = [
        "arn:aws:iam::766696030771:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-developer_f6defe724ee76f07",
        "arn:aws:iam::766696030771:role/MemberInfrastructureAccess",
        "arn:aws:iam::766696030771:role/github-actions-apply"
      ]
      lakeformation_read_only_admins = [
        "arn:aws:iam::766696030771:role/github-actions-plan"
      ]
    }
  }
}

module "data_lake_settings" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-data-platform-lakeformation.git//modules/data-lake-settings?ref=43c73a9"

  admins           = local.environments[local.environment].lakeformation_admins
  read_only_admins = local.environments[local.environment].lakeformation_read_only_admins
}

resource "aws_kms_key" "data_lake_kms_key" {
  description             = "KMS key for encrypting data in the data lake"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "data_lake_kms_alias" {
  name          = "alias/data-lake"
  target_key_id = aws_kms_key.data_lake_kms_key.id
}

module "data_lake_buckets" {
  for_each = toset(local.databases)
  source   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=ccc457c"

  bucket_prefix       = "${local.name}-${each.key}"
  bucket_namespace    = "account-regional"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  sse_algorithm       = "aws:kms"
  custom_kms_key      = aws_kms_key.data_lake_kms_key.arn

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}

module "databases" {
  for_each = toset(local.databases)
  source   = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/data-factory-glue-database?ref=ef60504"

  database_name = each.key

  storage = {
    bucket_name = module.data_lake_buckets[each.key].bucket.id
    prefix      = each.key
    kms_key_arn = aws_kms_key.data_lake_kms_key.arn
  }
}

data "aws_iam_policy_document" "data_lake_access_action_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:role/data-engineering-datalake-access-github-actions"]
    }
  }
}

resource "aws_iam_role" "lakeformation_share_role" {
  name               = "lakeformation-share-role"
  assume_role_policy = data.aws_iam_policy_document.data_lake_access_action_assume_role.json
}

# ref: https://docs.aws.amazon.com/lake-formation/latest/dg/cross-account-prereqs.html
resource "aws_iam_role_policy_attachment" "analytical_platform_share_policy_attachment" {
  role       = aws_iam_role.lakeformation_share_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
}


data "aws_iam_policy_document" "lakeformation_share_permissions_policy" {
  # Needed for LakeFormationAdmin to check the presense of the Lake Formation Service Role
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRolePolicy",
      "iam:GetRole"
    ]
    resources = [aws_iam_role.lakeformation_share_role.arn]
  }

  # Lake Formation permissions to manage cross-account access
  statement {
    effect = "Allow"
    actions = [

      # Permission management
      "lakeformation:GrantPermissions",
      "lakeformation:RevokePermissions",
      "lakeformation:BatchGrantPermissions",
      "lakeformation:BatchRevokePermissions",
      "lakeformation:RegisterResource",
      "lakeformation:DeregisterResource",
      "lakeformation:ListPermissions",
      "lakeformation:DescribeResource",

      # LF tag permissions (needed to create and grant tag-based access)
      "lakeformation:CreateLFTag",
      "lakeformation:CreateLFTagExpression",
      "lakeformation:GetLFTagExpression",
      "lakeformation:UpdateLFTag",
      "lakeformation:UpdateLFTagExpression",
      "lakeformation:DeleteLFTag",
      "lakeformation:GetResourceLFTags",
      "lakeformation:ListLFTags",
      "lakeformation:GetLFTag"

    ]
    resources = [
      #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
      "arn:aws:lakeformation:${local.current_account_region}:${local.current_account_id}:catalog:${local.current_account_id}"
    ]
  }

  # RAM permissions to create resource shares
  statement {
    effect = "Allow"
    actions = [
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare"
    ]
    resources = [
      "arn:aws:ram:${local.current_account_region}:${local.current_account_id}:resource-share/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:CreateDatabase",
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition",
      "glue:GetTags",
      "glue:DeleteDatabase",
      "glue:TagResource",
      "glue:UpdateDatabase"
    ]
    resources = [
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/*/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:userDefinedFunction/*/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:catalog"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:TagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PutRolePolicy",
      "iam:PassRole"

    ]
    resources = [
      "arn:aws:iam::${local.current_account_id}:role/*-location"
    ]
  }
}

resource "aws_iam_role_policy" "lakeformation_share_permissions_policy" {
  name   = "lakeformation-share-permissions-policy"
  role   = aws_iam_role.lakeformation_share_role.id
  policy = data.aws_iam_policy_document.lakeformation_share_permissions_policy.json
}
