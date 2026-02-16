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
  count = local.is-development ? 1 : 0

  role       = aws_iam_role.ssogen_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Need to tighten this policy to remove all resources
resource "aws_iam_policy" "ssogen_ec2_instance_policy" {
  name = "${local.application_name}-ssogen-instance-policy"

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
      "Action": ["kms:GenerateDataKey*", "kms:Decrypt"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssogen_ec2_policy" {
  count      = local.is-development || local.is-test ? 1 : 0
  role       = aws_iam_role.ssogen_ec2[count.index].name
  policy_arn = aws_iam_policy.ssogen_ec2_instance_policy.arn
}