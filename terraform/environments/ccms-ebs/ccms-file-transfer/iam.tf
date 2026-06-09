# ECS Task Execution Role

data "aws_iam_policy_document" "bc_ecs_task_execution_assume_role_policy" {
  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "bc_ecs_task_execution_role" {
  name               = "${local.application_name}-bc-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.bc_ecs_task_execution_assume_role_policy.json

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-ecs-role", local.application_name, local.environment)) }
  )
}

# ECS task execution role
resource "aws_iam_role" "bc_ecs_task_role" {
  name               = "${local.application_name}-bc-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.bc_ecs_task_execution_assume_role_policy.json

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-ecs-role", local.application_name, local.environment)) }
  )
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "bc_ecs_task_execution_role" {
  role       = aws_iam_role.bc_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS task role policy attachment
resource "aws_iam_role_policy_attachment" "bc_ecs_task_role" {
  role       = aws_iam_role.bc_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# ECS Secrets Manager Policy
resource "aws_iam_policy" "bc_ecs_secrets_policy" {
  name = "${local.application_name}-bc-ecs_secrets_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["${aws_secretsmanager_secret.sftp_bc_secrets.id}"]
    },
    {
      "Effect": "Allow",
      "Action": ["kms:GenerateDataKey*","kms:Decrypt"],
      "Resource": ["${aws_kms_key.s3_sftp_bc_kms_key.arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListObjects*",
          "s3:DeleteObject"
        ],
      "Resource": [
          "${module.s3-bucket-sftp-bc.bucket.arn}",
          "${module.s3-bucket-sftp-bc.bucket.arn}/*"
        ]
    }

  ]
}
EOF
}

# ECS secrets role policy attachment
resource "aws_iam_role_policy_attachment" "bc_ecs_secrets_policy_attachment" {
  role       = aws_iam_role.bc_ecs_task_execution_role.name
  policy_arn = aws_iam_policy.bc_ecs_secrets_policy.arn
}

# ECS secrets role policy attachment
resource "aws_iam_role_policy_attachment" "role_bc_ecs_secrets_policy_attachment" {
  role       = aws_iam_role.bc_ecs_task_role.name
  policy_arn = aws_iam_policy.bc_ecs_secrets_policy.arn
}
