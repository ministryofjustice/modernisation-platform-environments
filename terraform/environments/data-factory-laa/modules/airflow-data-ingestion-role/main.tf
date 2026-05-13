/**
 * This Terraform configuration defines an IAM role for Airflow with permissions to access specified S3 buckets.
 * The role is assumed by a web identity provider, allowing Airflow to interact with AWS resources securely.
 */

data "aws_iam_policy_document" "airflow_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.identity_provider_arn]
    }
  }
}

resource "aws_iam_role" "airflow" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.airflow_assume_role_policy.json
}

data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:Put*"
    ]
     resources = flatten([
       for bucket in var.data_buckets : [
         "arn:aws:s3:::${bucket}",
         "arn:aws:s3:::${bucket}/*",
       ]
     ])
  }
}

resource "aws_iam_role_policy" "s3" {
  name   = "s3"
  role   = aws_iam_role.airflow.id
  policy = data.aws_iam_policy_document.s3.json
}
