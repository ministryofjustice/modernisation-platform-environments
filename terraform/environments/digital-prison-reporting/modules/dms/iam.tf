# Create a role that can be assummed by the root account
data "aws_iam_policy_document" "dms_assume_role" {
  count = var.create && var.create_iam_roles ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }

  }
}

# CW Logs Role
# DMS CloudWatch Logs
resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  count = var.create && var.create_iam_roles ? 1 : 0

  name                  = "dms-${var.short_name}-cloudwatch-logs-role"
  description           = "DMS IAM role for CloudWatch logs permissions"
  permissions_boundary  = var.iam_role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.dms_assume_role[0].json
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"]
  force_detach_policies = true

  tags = var.tags
}

# DMS VPC
resource "aws_iam_role" "dmsvpcrole" {
  count = var.create && var.create_iam_roles ? 1 : 0

  name                  = "dms-${var.short_name}-vpc-role"
  description           = "DMS IAM role for VPC permissions"
  permissions_boundary  = var.iam_role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.dms_assume_role[0].json
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"]
  force_detach_policies = true

  tags = var.tags
}

# Attach an admin policy to the role
resource "aws_iam_role_policy" "dmsvpcpolicy" {
  count = var.create && var.create_iam_roles ? 1 : 0

  name = "dms-${var.short_name}-vpc-policy"
  role = aws_iam_role.dmsvpcrole[0].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DeleteNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#DMS Kinesis Endpoint role
resource "aws_iam_role" "dms-kinesis-role" {
  name = "dms-${var.short_name}-kenisis-endpoint-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "dms.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach an admin policy to the role
resource "aws_iam_role_policy" "dmskinesispolicy" {
  name = "dms-${var.short_name}-kinesis-policy"
  role = aws_iam_role.dms-kinesis-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "kms:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#DMS Role with kinesis Write Access
resource "aws_iam_role_policy_attachment" "dms-kinesis-attachment" {
  role       = aws_iam_role.dms-kinesis-role.name
  policy_arn = var.kinesis_stream_policy
}

#DMS DMS Operation role
resource "aws_iam_role" "dms-operator-role" {
  name = "dms-${var.short_name}-operator-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "dms.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach an admin policy to the Operator role
resource "aws_iam_role_policy" "dmsoperatorpolicy" {
  name = "dms-${var.short_name}-operator-policy"
  role = aws_iam_role.dms-operator-role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "kms:*",
                "cloudwatch:*",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DeleteNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#DMS Role with kinesis Write Access
resource "aws_iam_role_policy_attachment" "dms-operator-kinesis-attachment" {
  role       = aws_iam_role.dms-operator-role.name
  policy_arn = var.kinesis_stream_policy
}