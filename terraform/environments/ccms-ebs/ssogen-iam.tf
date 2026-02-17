# IAM Role for SSOGEN EC2
resource "aws_iam_role" "ssogen_ec2" {
  count = local.is-development || local.is-test ? 1 : 0

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
  count = local.is-development || local.is-test ? 1 : 0

  name = "ssogen-instance-profile-${local.environment}"
  role = aws_iam_role.ssogen_ec2[0].name
  tags = merge(local.tags, {
    Name = "ssogen-instance-profile-${local.environment}"
  })
}

# Attach SSM permissions (Session Manager, logging, patching, etc.)
resource "aws_iam_role_policy_attachment" "ssogen_ssm" {
  count = local.is-development || local.is-test ? 1 : 0

  role       = aws_iam_role.ssogen_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_kms_key" "ssogen_kms_key" {
  count  = local.is-development || local.is-test ? 1 : 0
  key_id = "alias/ec2_oracle_key"
}

resource "aws_kms_key" "ssogen_kms_key" {
  count       = local.is-development || local.is-test ? 1 : 0
  key_id      = "alias/ec2_oracle_key"
  description = "key-default-1"

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
  count = local.is-development || local.is-test ? 1 : 0
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
      "Resource": "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ds:CreateComputer",
        "ds:DescribeDirectories",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeTags",
        "logs:*",
        "ssm:*",
        "ec2messages:*"
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
      "Resource": ["arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:*"]
    },
    {
      "Effect": "Allow",
      "Action": ["kms:CreateGrant", "kms:DescribeKey", "kms:ReEncrypt", "kms:GenerateDataKeyWithoutPlainText", "kms:Decrypt"],
      "Resource": "${data.aws_kms_key.ssogen_kms_key[count.index].arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssogen_ec2_policy" {
  count      = local.is-development || local.is-test ? 1 : 0
  role       = aws_iam_role.ssogen_ec2[count.index].name
  policy_arn = aws_iam_policy.ssogen_ec2_instance_policy[count.index].arn
}