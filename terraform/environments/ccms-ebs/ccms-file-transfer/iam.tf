# ECS Task Execution Role

data "aws_iam_policy_document" "ecs_task_execution_assume_role_policy" {
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
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.sftp_suffix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role_policy.json

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-ecs-task-execution-role" }
  )
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.sftp_suffix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role_policy.json

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-ecs-task-role" }
  )
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS task role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# ECS Secrets Manager Policy
resource "aws_iam_policy" "ecs_secrets_policy" {
  name = "${local.sftp_suffix}-ecs_secrets_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["${aws_secretsmanager_secret.sftp_secrets.id}"]
    },
    {
      "Effect": "Allow",
      "Action": ["kms:GenerateDataKey*","kms:Decrypt"],
      "Resource": ["${aws_kms_key.s3_sftp_kms_key.arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
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
resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# ECS secrets role policy attachment
resource "aws_iam_role_policy_attachment" "role_ecs_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}
