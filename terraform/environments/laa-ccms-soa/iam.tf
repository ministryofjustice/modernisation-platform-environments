#--ECS
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

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.application_data.accounts[local.environment].app_name}-WorldTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_secrets_policy" {
  name   = "${local.application_data.accounts[local.environment].app_name}-ecs_secrets_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["arn:aws:secretsmanager:eu-west-2:*:secret:ccms/soa*"]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

resource "aws_iam_policy" "soa_s3_policy" {
  name        = "${local.application_data.accounts[local.environment].app_name}-s3-policy"
  description = "${local.application_data.accounts[local.environment].app_name} s3-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject",
                "s3:RestoreObject"
            ],
            "Resource": [
                "arn:aws:s3:::${local.application_data.accounts[local.environment].inbound_s3_bucket_name}/*",
                "arn:aws:s3:::${local.application_data.accounts[local.environment].inbound_s3_bucket_name}",
                "arn:aws:s3:::${local.application_data.accounts[local.environment].outbound_s3_bucket_name}/*",
                "arn:aws:s3:::${local.application_data.accounts[local.environment].outbound_s3_bucket_name}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "soa_s3_policy_cortex_deps" {
  count       = local.is-production ? 1 : 0
  name        = "${local.application_data.accounts[local.environment].app_name}-s3-policy-cortex-deps"
  description = "${local.application_data.accounts[local.environment].app_name} s3-policy-cortex-deps"

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

#--EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_data.accounts[local.environment].app_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.application_data.accounts[local.environment].app_name}-ec2-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ec2_instance_policy" {
  name = "${local.application_data.accounts[local.environment].app_name}-ec2-instance-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories",
                "ec2messages:*",
                "ec2:DescribeTags",
                "ec2:DescribeInstanceStatus",
                "cloudwatch:PutMetricData",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecs:SubmitTaskStateChange",
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
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": "ssm.amazonaws.com"
                }
            }
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
                "ssmmessages:OpenDataChannel",
                "ssm:AddTagsToResource",
                "ssm:DescribeDocument",
                "ssm:ExecuteAPI",
                "ssm:GetAccessToken",
                "ssm:GetCalendar",
                "ssm:GetDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:ListInstanceAssociations",
                "ssm:ListTagsForResource",
                "ssm:PutCalendar",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:PutInventory",
                "ssm:RemoveTagsFromResource",
                "ssm:StartAccessRequest",
                "ssm:StartExecutionPreview",
                "ssm:UpdateInstance*"
            ],
            "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": ["secretsmanager:GetSecretValue"],
          "Resource": [
            "arn:aws:secretsmanager:eu-west-2:*:secret:ccms/soa/deploy-*",
            "arn:aws:secretsmanager:eu-west-2:*:secret:ccms/soa/password",
            "arn:aws:secretsmanager:eu-west-2:*:secret:ccms/soa/xxsoa/ds/password"
          ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.soa_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy_cortex_deps" {
  count      = local.is-production ? 1 : 0
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.soa_s3_policy_cortex_deps[0].arn
}

#--Alerting
data "aws_iam_policy_document" "alerting_sns" {
  version = "2012-10-17"
  statement {
    sid    = "EventsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.alerts.arn,
    ]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
      ]
    }
  }
  statement {
    sid    = "AlarmsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.alerts.arn,
    ]
    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values = [
        "arn:aws:cloudwatch:eu-west-2:${local.aws_account_id}:alarm:*"
      ]
    }
  }
  statement {
    sid    = "AllowPublishSnsTopicRoot"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.alerts.arn,
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.aws_account_id}:root",
      ]
    }
  }
}

data "aws_iam_policy_document" "guardduty_alerting_sns" {
  version = "2012-10-17"
  statement {
    sid    = "EventsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish",
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