#######################################
# ECS Task Execution Role
#######################################

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.application_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ecs-role", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#######################################
# ECS Secrets Manager Policy
#######################################

resource "aws_iam_policy" "ecs_secrets_policy" {
  name = "${local.application_name}-${local.environment}-ecs-secrets-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

#######################################
# EC2 Instance Role + Profile
#######################################

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.application_name}-ec2-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "ec2.amazonaws.com" }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_instance_policy" {
  name = "${local.application_name}-ec2-instance-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeTags",
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:UpdateContainerInstancesState",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ds:CreateComputer",
        "ds:DescribeDirectories",
        "ec2:DescribeInstanceStatus",
        "logs:*",
        "ssm:*",
        "ec2messages:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*",
      "Condition": { "StringLike": { "iam:AWSServiceName": "ssm.amazonaws.com" } }
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:DeleteServiceLinkedRole",
        "iam:GetServiceLinkedRoleDeletionStatus"
      ],
      "Resource": "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}


# S3 Cortex Deps Bucket Access Policy
resource "aws_iam_policy" "s3_policy_cortex_deps" {
  count       = local.is-production ? 1 : 0
  name        = "${local.application_name}-s3-policy-cortex-deps"
  description = "${local.application_name} s3-policy-cortex-deps"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${local.application_data.accounts[local.environment].cortex_deps_bucket_name}/*",
                "arn:aws:s3:::${local.application_data.accounts[local.environment].cortex_deps_bucket_name}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_policy_cortex_deps" {
  count      = local.is-production ? 1 : 0
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.s3_policy_cortex_deps[0].arn
}

data "aws_iam_policy_document" "guardduty_alerting_sns" {
  version = "2012-10-17"
  statement {
    sid    = "EventsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.guardduty_alerts.arn
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_alerting_sns" {
  version = "2012-10-17"
  statement {
    sid    = "EventsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.cloudwatch_alerts.arn
    ]
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com"
      ]
    }

  }
}

resource "aws_kms_key" "cloudwatch_sns_alerts_key" {
  description             = "KMS Key for CloudWatch SNS Alerts Encryption"
  deletion_window_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cloudwatch-sns-alerts-kms-key", local.application_name, local.environment)) }
  )
}

resource "aws_kms_key_policy" "sns_alerts_key_policy" {
  key_id = data.aws_kms_key.sns_alerts_key.key_id
  policy = data.aws_iam_policy_document.cloudwatch_sns_encryption.json
}

data "aws_iam_policy_document" "cloudwatch_sns_encryption" {
  version = "2012-10-17"
  statement {
    sid    = "AllowCloudWatchSNSUseOfTheKey"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
        "event.amazonaws.com"
      ]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = [
      "*"
    ]
  }
}
