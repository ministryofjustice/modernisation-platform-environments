locals {
  current_account_id     = data.aws_caller_identity.current.account_id
  current_account_region = data.aws_region.current.id
}

data "aws_iam_policy_document" "ap_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["analytical-platform-common-production"]}:role/data-engineering-datalake-access-github-actions"]
    }
  }
}

resource "aws_iam_role" "analytical_platform_share_role" {
  name = "lakeformation-share-role"

  assume_role_policy = data.aws_iam_policy_document.ap_assume_role.json
}

# ref: https://docs.aws.amazon.com/lake-formation/latest/dg/cross-account-prereqs.html
resource "aws_iam_role_policy_attachment" "analytical_platform_share_policy_attachment" {
  role       = aws_iam_role.analytical_platform_share_role.name
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
    resources = [
      "*"
    ]
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

  # Required to allow Lake Formation to access S3 on behalf of the role
  statement {
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${local.current_account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"
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
  role   = aws_iam_role.analytical_platform_share_role.id
  policy = data.aws_iam_policy_document.lakeformation_share_permissions_policy.json
}
