resource "aws_ecs_task_definition" "ecs_task_definition" {
  family             = "${var.app_name}-task-definition" 
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = [
    "EC2",
  ]

  volume {
    name = var.task_definition_volume
  }

  container_definitions = var.task_definition

  runtime_platform {
     operating_system_family = "WINDOWS_SERVER_2019_CORE"
  #   cpu_architecture        = "X86_64"
  }

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-windows-task-definition"
    }
  )
}


# ECS task execution role data
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
data "aws_iam_policy_document" "ecs_task_execution_role" {
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

resource "aws_iam_policy" "ecs_task_execution_s3_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${var.app_name}-ecs-task-execution-s3-policy"
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-task-execution-s3-policy"
    }
  )
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:*Object*",
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:ReEncrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}


# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-task-execution-role"
    }
  )
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_manager" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy_attachment" "ecs_task_s3_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_s3_policy.arn
}


