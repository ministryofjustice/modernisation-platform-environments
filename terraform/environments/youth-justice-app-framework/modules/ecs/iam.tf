resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#todo add missing policies to this role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#Todo refine this it is too permissive
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

#Todo refine this it is too permissive
resource "aws_iam_role_policy_attachment" "ecs_task_s3_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#Todo refine this it is too permissive
resource "aws_iam_role_policy_attachment" "ecs_task_ses_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs-secrets-access" {
  name        = "${var.cluster_name}-ecs-secrets-access"
  description = "Allows ECS tasks to access secrets in Secrets Manager"
  policy = templatefile("${path.module}/ecs_secrets_access.json", {
    secret_arns    = var.ecs_secrets_access_policy_secret_arns
    secret_kms_key = var.secret_kms_key_arn
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs-secrets-access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_task_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs-secrets-access.arn
}

#for each for any other policies
resource "aws_iam_role_policy_attachment" "ecs_task_role_additional_policies" {
  for_each = { for idx, arn in var.ecs_role_additional_policies_arns : idx => arn }

  role       = aws_iam_role.ecs_task_role.name
  policy_arn = each.value
}
