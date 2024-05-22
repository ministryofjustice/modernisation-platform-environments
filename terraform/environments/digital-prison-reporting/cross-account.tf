### Cross Account Role

## Redshift DataAPI Cross Account Role, CP -> MP
# Redshift DataAPI Assume Policy
data "aws_iam_policy_document" "redshift_dataapi_cross_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754256621582:root"]
    }

  }
}

# Redshift DataAPI Role
resource "aws_iam_role" "redshift_dataapi_cross_role" {
  name                  = "${local.project}-redshift-data-api-cross-role"
  description           = "Redshift Data API Cross Account Role, CP to MP"
  assume_role_policy    = data.aws_iam_policy_document.redshift_dataapi_cross_assume.json
  force_detach_policies = true

  tags = merge(
    local.tags,
    {
      Name              = "${local.project}-redshift-data-api-cross-role"
      Resource_Type     = "iam"
      Jira              = "DPR2-751"
      Resource_Group    = "Front-End"
    }
  )
}

# Redshift DataAPI Policy Document
data "aws_iam_policy_document" "redshift_dataapi" {
  statement {
    actions = [
        "redshift-data:ListTables",
        "redshift-data:DescribeTable",
        "redshift-data:ListSchemas",
        "redshift-data:ListDatabases"
    ]
    resources = [
      "arn:aws:redshift:${local.account_region}:${local.account_id}:cluster:*"
    ]
  }

  statement {
    actions = [
        "redshift-data:GetStatementResult",
        "redshift-data:DescribeStatement",
        "redshift-data:ListStatements"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:aws:secretsmanager:${local.account_region}:${local.account_id}:secret:*"
    ]
  }

  statement {
    actions = [
        "secretsmanager:ListSecrets"
    ]
    resources = [
      "*"
    ]
  }    

}

# Redshift DataAPI Policy
resource "aws_iam_policy" "redshift_dataapi_cross_policy" {
  name        = "dpr-redshift-policy"
  description = "Extra Policy for AWS Redshift"
  policy      = data.aws_iam_policy_document.redshift_dataapi.json
}

# Redshift DataAPI Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "redshift_dataapi" {
  role       = aws_iam_role.redshift_dataapi_cross_role.name
  policy_arn = aws_iam_policy.redshift_dataapi_cross_policy.arn
}