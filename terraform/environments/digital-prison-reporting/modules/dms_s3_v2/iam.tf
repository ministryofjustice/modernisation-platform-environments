#DMS S3 Endpoint role
resource "aws_iam_role" "dms-s3-role" {
  count = var.setup_dms_endpoints && var.setup_dms_iam ? 1 : 0

  name = "${var.project_id}-dms-${var.short_name}-s3-endpoint-role"
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

# Attach s3 target operation policy to the role
resource "aws_iam_policy" "dms-s3-target-policy" {
  count = var.setup_dms_endpoints && var.setup_dms_iam ? 1 : 0

  name = "${var.project_id}-dms-${var.short_name}-s3-target-policy"

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

#DMS Role with s3 Write Access
resource "aws_iam_role_policy_attachment" "dms-s3-attachment" {
  count = var.setup_dms_endpoints && var.setup_dms_iam ? 1 : 0

  role       = aws_iam_role.dms-s3-role[0].name
  policy_arn = aws_iam_policy.dms-s3-target-policy[0].arn
}

#DMS Operation s3 target role
resource "aws_iam_role" "dms-operator-s3-target-role" {
  count = var.setup_dms_endpoints && var.setup_dms_iam ? 1 : 0

  name = "${var.project_id}-dms-${var.short_name}-operator-s3-target-role"
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
resource "aws_iam_policy" "dms-operator-s3-policy" {
  count = var.setup_dms_endpoints && var.setup_dms_iam ? 1 : 0

  name = "${var.project_id}-dms-${var.short_name}-operator-s3-target-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
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
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*Object*",
                "s3:PutObjectTagging",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3::*:dpr-*",
                "arn:aws:s3::*:dpr-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListAllMyBuckets",
                "s3:ListAccessPoints",
                "s3:ListJobs",
                "s3:ListObjects"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#DMS Role with s3 Write Access
resource "aws_iam_role_policy_attachment" "dms-operator-s3-attachment" {
  count = var.setup_dms_endpoints && var.setup_dms_iam ? 1 : 0

  role       = aws_iam_role.dms-operator-s3-target-role[0].name
  policy_arn = aws_iam_policy.dms-operator-s3-policy[0].arn
}