# IAM Role for SSOGEN EC2
resource "aws_iam_role" "ssogen_ec2" {
  count = local.ssogen_enabled ? 1 : 0

  name = "ssogen-ec2-role-${local.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = merge(local.tags, {
    Name = "ssogen-ec2-role-${local.environment}"
  })
}

# Instance Profile to attach to EC2
resource "aws_iam_instance_profile" "ssogen_instance_profile" {
  count = local.ssogen_enabled ? 1 : 0

  name = "ssogen-instance-profile-${local.environment}"
  role = aws_iam_role.ssogen_ec2[0].name
  tags = merge(local.tags, {
    Name = "ssogen-instance-profile-${local.environment}"
  })
}

# Customer-managed equivalent of AmazonSSMManagedInstanceCore.
resource "aws_iam_policy" "ssogen_ssm_custom" {
  count = local.ssogen_enabled ? 1 : 0

  name        = "CustomSSMManagedInstanceCore"
  description = "Standard Systems Manager core permissions for SSOGEN EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ]
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        "Resource" : ["arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the customer-managed SSM core policy to the SSOGEN EC2 role.
resource "aws_iam_role_policy_attachment" "ssogen_ssm_custom" {
  count = local.ssogen_enabled ? 1 : 0

  role       = aws_iam_role.ssogen_ec2[count.index].name
  policy_arn = aws_iam_policy.ssogen_ssm_custom[count.index].arn
}

resource "aws_kms_alias" "a" {
  count         = local.ssogen_enabled ? 1 : 0
  name          = "alias/ssogen-key-alias"
  target_key_id = aws_kms_key.ssogen_kms_key[0].key_id
}

resource "aws_kms_key" "ssogen_kms_key" {
  count       = local.ssogen_enabled ? 1 : 0
  description = "kms key for ssogen ami"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowRootAccountAdminForDevAccount",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${jsondecode(data.aws_secretsmanager_secret_version.dev_account_secret[count.index].secret_string).dev_account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowRootAccountAdminForDevAccount",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${jsondecode(data.aws_secretsmanager_secret_version.dev_account_secret[count.index].secret_string).preprod_account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowRootAccountAdminForDevAccount",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${jsondecode(data.aws_secretsmanager_secret_version.dev_account_secret[count.index].secret_string).prod_account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow service-linked role use of the customer managed key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow ec2 instance role use of the customer managed key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.ssogen_ec2[count.index].name}"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:CreateGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : true
          }
        }
      }
    ]
  })
}


# Need to tighten this policy to remove all resources
resource "aws_iam_policy" "ssogen_ec2_instance_policy" {
  count = local.ssogen_enabled ? 1 : 0
  name  = "${local.application_name_ssogen}-instance-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*ssogen*:*",
        "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:*var-log*:*"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup"
        ],
        "Resource": "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
      },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ds:CreateComputer",
        "ds:DescribeDirectories",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeTags",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*",
      "Condition": { "StringLike": { "iam:AWSServiceName": "ssm.amazonaws.com" } }
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:DeleteServiceLinkedRole",
        "iam:GetServiceLinkedRoleDeletionStatus"
      ],
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*"
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
    },
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}-dev-account-secrets"]
    },
    {
      "Effect": "Allow",
      "Action": ["kms:DescribeKey", "kms:ReEncrypt", "kms:GenerateDataKeyWithoutPlainText", "kms:Decrypt"],
      "Resource": "${aws_kms_key.ssogen_kms_key[count.index].arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssogen_ec2_policy" {
  count      = local.ssogen_enabled ? 1 : 0
  role       = aws_iam_role.ssogen_ec2[count.index].name
  policy_arn = aws_iam_policy.ssogen_ec2_instance_policy[count.index].arn
}

resource "aws_iam_policy" "ssogen_ec2_s3_policy" {
  count = local.ssogen_enabled ? 1 : 0
  name  = "${local.application_name_ssogen}-s3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": ["${aws_s3_bucket.ccms_ebs_shared.arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectAttributes"
      ],
      "Resource": ["${aws_s3_bucket.ccms_ebs_shared.arn}/*"]
    }    
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssogen_ec2_s3_policy_attachment" {
  count      = local.ssogen_enabled ? 1 : 0
  role       = aws_iam_role.ssogen_ec2[count.index].name
  policy_arn = aws_iam_policy.ssogen_ec2_s3_policy[count.index].arn
}