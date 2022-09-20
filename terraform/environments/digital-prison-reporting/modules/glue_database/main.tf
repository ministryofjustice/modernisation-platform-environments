locals {
}

resource "aws_glue_catalog_database" "glue_database" {
  count = var.create_db ? 1 : 0

  name = var.name

  description  = var.description
  catalog_id   = var.catalog
  location_uri = var.location_uri
  parameters   = var.params

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = []
}

resource "aws_glue_resource_policy" "example" {
  policy = data.aws_iam_policy_document.glue-example-policy.json
}

data "aws_iam_policy_document" "glue-example-policy" {
  statement {
    actions = [
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateSchema",
      "glue:DeleteSchema",      
    ]
    resources = ["arn:aws:glue:${var.aws_region}:${var.aws_account_id}:*"]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}