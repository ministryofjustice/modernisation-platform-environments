locals {
  table_name = "${local.project}-data-product-definition"
}

module "dynamo_table_dpd" {
  source              = "./modules/dynamo_tables"
  create_table        = true
  autoscaling_enabled = false
  name                = local.table_name

  hash_key    = "data-product-id"
  range_key   = "category"
  table_class = "STANDARD"
  ttl_enabled = false

  attributes = [
    {
      name = "data-product-id"
      type = "S"
    },
    {
      name = "category"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "category-index"
      hash_key        = "category"
      projection_type = "ALL"
    }
  ]

  tags = merge(
    local.all_tags,
    {
      dpr-name          = local.table_name
      dpr-resource-type = "Dynamo Table"
    }
  )
}

// Allow GitHub Actions run from the definitions repo to deploy/undeploy DPDs in the DynamoDB table.

data "aws_iam_policy_document" "dpd_table_github_deploy_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringLike"
      values   = ["repo:ministryofjustice/hmpps-dpr-data-product-definitions:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
  }
}

data "aws_iam_policy_document" "dpd_table_github_deploy_put_policy" {
  statement {
    sid    = "DeployDpdItems"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem"
    ]
    resources = [
      module.dynamo_table_dpd.dynamodb_table_arn
    ]
  }
}

resource "aws_iam_policy" "dpd_table_github_deploy_put_policy" {
  name        = "${local.project}-dpd-table-github-deploy-put-policy"
  description = "Allows deploying DPDs to the DPD DDB table"
  policy      = data.aws_iam_policy_document.dpd_table_github_deploy_put_policy.json
}

resource "aws_iam_role" "dpd_table_github_deploy_role" {
  name               = "${local.project}-dpd-table-github-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.dpd_table_github_deploy_assume_role_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "dpd_table_github_deploy_put_policy" {
  policy_arn = aws_iam_policy.dpd_table_github_deploy_put_policy.arn
  role       = aws_iam_role.dpd_table_github_deploy_role.name
}

// Allow the Main API to read the DPD table.

data "aws_iam_policy_document" "dpd_table_read_policy" {
  statement {
    sid    = "ReadDpdItems"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    ]
    resources = [
      module.dynamo_table_dpd.dynamodb_table_arn,
      "${module.dynamo_table_dpd.dynamodb_table_arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "dpd_table_read_policy" {
  name        = "${local.project}-dpd-table-read-policy"
  description = "Allows reading DPDs from the DPD DDB table"
  policy      = data.aws_iam_policy_document.dpd_table_read_policy.json
}

// Attach DDB read policy to existing cross account role
resource "aws_iam_role_policy_attachment" "dpd_table_read_policy" {
  policy_arn = aws_iam_policy.dpd_table_read_policy.arn
  role       = aws_iam_role.dataapi_cross_role.name
}
