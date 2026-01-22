locals {
  replication_enabled = var.production_dev == "prod" || var.production_dev == "test"
}

resource "aws_iam_role" "replication_role" {
  count              = local.replication_enabled ? 1 : 0
  name               = "AWSS3BucketReplication"
  assume_role_policy = data.aws_iam_policy_document.s3-assume-role-policy.json
  tags               = var.local_tags
}


# S3 bucket replication: assume role policy
data "aws_iam_policy_document" "s3-assume-role-policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "replication_policy" {
  count    = local.replication_enabled ? 1 : 0
  name     = "AWSS3BucketReplication${var.production_dev}"
  policy   = data.aws_iam_policy_document.replication-policy.json
}

# S3 bucket replication: role policy
# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "replication-policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      local.replication_enabled ? "arn:aws:kms:eu-west-2:${var.replication_details["account_id"]}:key/${var.replication_details["${var.data_feed}_${var.order_type}_kms_id"]}" : "",
      module.kms_key.key_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"

    ]
    resources = [module.this-bucket.bucket.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.this-bucket.bucket.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]

    resources = [local.replication_enabled ? "arn:aws:s3:::${var.replication_details["${var.data_feed}_${var.order_type}_bucket"]}/*" : ""]

  }
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = local.replication_enabled ? 1 : 0
  role       = aws_iam_role.replication_role[count.index].name
  policy_arn = aws_iam_policy.replication_policy[count.index].arn
}

resource "aws_s3_bucket_replication_configuration" "default" {
  for_each = local.replication_enabled ? toset(["run"]) : []
  bucket   = module.this-bucket.bucket.id
  role     = aws_iam_role.replication_role[0].arn
  rule {
    id       = "SourceToDestinationReplication"
    status   = local.replication_enabled ? "Enabled" : "Disabled"
    priority = 0

    destination {
      account       = var.replication_details["account_id"]
      bucket        = local.replication_enabled ? "arn:aws:s3:::${var.replication_details["${var.data_feed}_${var.order_type}_bucket"]}" : ""
      encryption_configuration {
        replica_kms_key_id = local.replication_enabled != "" ? "arn:aws:kms:eu-west-2:${var.replication_details["account_id"]}:key/${var.replication_details["${var.data_feed}_${var.order_type}_kms_id"]}" : ""
      }
      access_control_translation {
        owner = "Destination"
      }
    }

    delete_marker_replication {
      status = "Disabled"
    }

    filter {
      prefix = ""
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = (local.replication_enabled != false) ? "Enabled" : "Disabled"
      }
    }
  }
}