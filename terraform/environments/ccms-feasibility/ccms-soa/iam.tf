# EC2 instance role for ECS cluster nodes (shared by admin and managed capacity providers)

resource "aws_iam_role" "ecs_ec2" {
  name = "${local.component_name}-${local.env_label}-ecs-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-ec2-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_container_service" {
  role       = aws_iam_role.ecs_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_ssm" {
  role       = aws_iam_role.ecs_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ecs_ec2_secrets" {
  name = "${local.component_name}-${local.env_label}-ecs-ec2-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:PutSecretValue",
        "secretsmanager:CreateSecret",
      ]
      Resource = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.component_name}*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_secrets" {
  role       = aws_iam_role.ecs_ec2.name
  policy_arn = aws_iam_policy.ecs_ec2_secrets.arn
}

resource "aws_iam_policy" "ecs_ec2_s3_fileops" {
  name = "${local.component_name}-${local.env_label}-ecs-ec2-s3-fileops-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:RestoreObject",
      ]
      Resource = [
        data.aws_s3_bucket.inbound.arn,
        "${data.aws_s3_bucket.inbound.arn}/*",
        data.aws_s3_bucket.outbound.arn,
        "${data.aws_s3_bucket.outbound.arn}/*",
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_s3_fileops" {
  role       = aws_iam_role.ecs_ec2.name
  policy_arn = aws_iam_policy.ecs_ec2_s3_fileops.arn
}

resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "${local.component_name}-${local.env_label}-ecs-ec2-profile"
  role = aws_iam_role.ecs_ec2.name

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-ec2-profile"
  })
}

# ECS task execution role (shared by admin and managed services)

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.component_name}-${local.env_label}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_secrets" {
  name = "${local.component_name}-${local.env_label}-ecs-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.component_name}*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_secrets.arn
}


resource "aws_kms_grant" "autoscaling_ebs" {
  name              = "${local.component_name}-${local.env_label}-autoscaling-ebs-grant"
  key_id            = data.aws_kms_key.ebs_shared.arn
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey",
    "CreateGrant",
  ]
}
