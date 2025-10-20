data "aws_iam_policy_document" "connector_ecs_task_role" {
  version = "2012-10-17"

  statement {
    sid     = "ECSTaskAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Connector ECS Task Role
resource "aws_iam_role" "connector_ecs_task_role" {
  name               = "${local.connector_app_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.connector_ecs_task_role.json

  tags = merge(
    local.tags,
    { Name = lower(format("%s-ecs-task-role", local.connector_app_name)) }
  )
}


# S3 Access Policy
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${local.connector_app_name}-${local.environment}-s3-access"
  description = "S3 access policy for ${local.connector_app_name} logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = module.s3_ccms_oia.bucket.arn
      },
      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${module.s3_ccms_oia.bucket.arn}/*"
      }
    ]
  })

  tags = local.tags
}

# Attach S3 policy to Connector ECS task role
resource "aws_iam_role_policy_attachment" "s3_access_connector_ecs" {
  role       = aws_iam_role.connector_ecs_task_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}