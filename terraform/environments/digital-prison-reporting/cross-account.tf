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
  name                  = "${local.project}-redshift-data-api-cross-role-${local.env}"
  description           = "Redshift Data API Cross Account Role, CP to MP"
  assume_role_policy    = data.aws_iam_policy_document.redshift_dataapi_cross_assume.json
  force_detach_policies = true

  tags = merge(
    local.tags,
    {
      Name              = "${local.project}-redshift-data-api-cross-role-${local.env}"
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
        "redshift-data:ListDatabases",
        "redshift-data:ExecuteStatement"
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

# Athena API Policy Document
data "aws_iam_policy_document" "athena_api" {
  statement {
    actions = [
      "athena:GetDataCatalog",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${local.account_region}:${local.account_id}:workgroup/primary"
    ]
  }

  statement {
    actions = [
      "athena:ListWorkGroups"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${local.account_region}:${local.account_id}:function:dpr-athena-federated-query-oracle-function"
    ]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::dpr-*/*"
    ]
  }

  statement {
    actions = [
      "kms:GenerateDataKey"
    ]
    resources = [
      "arn:aws:kms:*:771283872747:key/*"
    ]
  }

}

# Redshift DataAPI Policy
resource "aws_iam_policy" "redshift_dataapi_cross_policy" {
  name        = "${local.project}-redshift-data-api-cross-policy"
  description = "Extra Policy for AWS Redshift"
  policy      = data.aws_iam_policy_document.redshift_dataapi.json
}

# Athena API Policy
resource "aws_iam_policy" "athena_api_cross_policy" {
  name        = "${local.project}-athena-api-cross-policy"
  description = "Extra Policy for AWS Athena"
  policy      = data.aws_iam_policy_document.athena_api.json
}

# Redshift DataAPI Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "redshift_dataapi" {
  role       = aws_iam_role.redshift_dataapi_cross_role.name
  policy_arn = aws_iam_policy.redshift_dataapi_cross_policy.arn
}

# Athena API Role/Policy Attachement
resource "aws_iam_role_policy_attachment" "athena_api" {
  role       = aws_iam_role.redshift_dataapi_cross_role.name
  policy_arn = aws_iam_policy.athena_api_cross_policy.arn
}