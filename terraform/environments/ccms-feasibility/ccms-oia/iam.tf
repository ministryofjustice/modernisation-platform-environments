# EC2 instance role for ECS cluster nodes

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

resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "${local.component_name}-${local.env_label}-ecs-ec2-profile"
  role = aws_iam_role.ecs_ec2.name

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-ec2-profile"
  })
}

# ECS task execution role (shared across all three OIA services)

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
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.component_name}*",
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.opahub_name}*",
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.connector_name}*",
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.adaptor_name}*",
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_secrets.arn
}

# Grant the Auto Scaling service-linked role access to the cross-account shared EBS KMS key.
# Service-linked roles cannot have IAM policies attached, so a KMS grant is required.
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

# Connector task role for S3 document bucket access

resource "aws_iam_role" "connector_task" {
  name = "${local.connector_name}-${local.env_label}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.connector_name}-${local.env_label}-task-role"
  })
}

resource "aws_iam_policy" "connector_s3" {
  name = "${local.connector_name}-${local.env_label}-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.connector_docs.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:PutObjectAcl"]
        Resource = "${aws_s3_bucket.connector_docs.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "connector_s3" {
  role       = aws_iam_role.connector_task.name
  policy_arn = aws_iam_policy.connector_s3.arn
}
