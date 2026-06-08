/**
  * This Terraform configuration defines an IAM role for CADeT (Create a Derived Table) with a trust policy that allows it to be assumed by a federated identity provider (Usually Airflow or GitHub Actions). The role is granted permissions to perform various actions on AWS Lake Formation and AWS Glue services.
  */

data "aws_iam_policy_document" "airflow_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Federated"
      identifiers = [var.identity_provider_arn]
    }
  }
}

resource "aws_iam_role" "cadet" {
  name               = "cadet"
  assume_role_policy = data.aws_iam_policy_document.airflow_assume_role_policy.json
}

data "aws_iam_policy_document" "cadet_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lakeformation:*",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:UpdatePartition",
      "glue:GetPartition",
      "glue:GetPartitions",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cadet_policy" {
  name   = "cadet"
  role   = aws_iam_role.cadet.id
  policy = data.aws_iam_policy_document.cadet_policy.json
}
