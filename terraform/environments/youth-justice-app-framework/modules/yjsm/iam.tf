resource "aws_iam_role" "yjsm_ec2_role" {
  name = "yjsm-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_secretsmanager_secrets" "all_secrets" {}

resource "aws_iam_instance_profile" "yjsm_ec2_profile" {
  name = "yjsm-ec2-instance"
  role = aws_iam_role.yjsm_ec2_role.name
}

#todo add missing policies to this role
resource "aws_iam_role_policy_attachment" "yjsm_ssm_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "yjsm_cloudwatch_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "yjsm_ec2_readonly_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "yjsm_s3_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "yjsm_secret_tmp_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "yjsm_ses_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

# TODO FIX POLICY SO WE CAN REMOVE SecretsManagerReadWrite
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "secrets_manager_access"
  description = "Policy to allow access to specific secrets in Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets",
          "secretsmanager:CancelRotateSecret"
        ]
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secrets.all_secrets.arns
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = var.secret_kms_key_arn
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_secrets_manager_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_policy" "ecs_task_inspection" {
  name        = "EC2ListAndDescribeTasksPolicy"
  description = "Allows EC2 role to list and describe ECS tasks"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:ListTasks"
        ],
        Resource = "arn:aws:ecs:${var.region}:${var.account_id}:cluster/${var.cluster_name}"
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeTasks"
        ],
        Resource = "arn:aws:ecs:${var.region}:${var.account_id}:task/${var.cluster_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecs_task_inspection_policy" {
  role       = aws_iam_role.yjsm_ec2_role.name
  policy_arn = aws_iam_policy.ecs_task_inspection.arn
}
