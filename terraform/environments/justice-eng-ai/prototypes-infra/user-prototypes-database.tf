data "aws_partition" "prototype_database" {}

data "aws_iam_policy_document" "prototype_database_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.prototype_database.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_iam_role" "prototype_database" {
  name               = "${local.application_name}-prototype-database"
  description        = "Shared task role for prototype user-data access."
  assume_role_policy = data.aws_iam_policy_document.prototype_database_assume_role.json
  tags               = local.tags
}

# Tables are created outside Terraform, one per prototype build. Access is
# currently shared across all tables in this account and region.
data "aws_iam_policy_document" "prototype_database" {
  statement {
    sid = "PrototypeUserData"
    actions = [
      "dynamodb:Scan",
      "dynamodb:PutItem",
    ]
    resources = [
      "arn:${data.aws_partition.prototype_database.partition}:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/*",
    ]
  }
}

resource "aws_iam_policy" "prototype_database" {
  name        = "${local.application_name}-prototype-database"
  description = "Read draft history and append prototype drafts and submissions."
  policy      = data.aws_iam_policy_document.prototype_database.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "prototype_database" {
  role       = aws_iam_role.prototype_database.name
  policy_arn = aws_iam_policy.prototype_database.arn
}

output "prototype_database_task_role_arn" {
  description = "Use as task_role_arn on prototype ECS task definitions, not execution_role_arn."
  value       = aws_iam_role.prototype_database.arn
}

output "prototype_database_policy_arn" {
  description = "Shared DynamoDB access policy, also attachable to separately managed prototype task roles."
  value       = aws_iam_policy.prototype_database.arn
}