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

# S3 Read Write Policy Attachement
resource "aws_iam_role_policy_attachment" "athena_api" {
  role       = aws_iam_role.redshift_dataapi_cross_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}