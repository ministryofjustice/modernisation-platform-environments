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

# EC2 Instance Role

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.sftp_suffix}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${local.sftp_suffix}-ec2-instance-role"

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
  name = "${local.sftp_suffix}-ec2-instance-policy"

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
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:PutLogEvents",
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceInformation",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation",
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
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

# S3 Access Policy
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${local.sftp_env_suffix}-s3-access"
  description = "S3 access policy for ${local.sftp_env_suffix} documents"

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
        Resource = module.s3-bucket-sftp-bc.bucket.arn
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
        Resource = "${module.s3-bucket-sftp-bc.bucket.arn}/*"
      }
    ]
  })

  tags = local.tags
}

# Attach S3 policy to existing EC2 instance role
resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


# S3 Cortex Deps Bucket Access Policy
resource "aws_iam_policy" "s3_policy_cortex_deps" {
  count       = local.is-production ? 1 : 0
  name        = "${local.sftp_suffix}-s3-policy-cortex-deps"
  description = "${local.sftp_suffix} s3-policy-cortex-deps"

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