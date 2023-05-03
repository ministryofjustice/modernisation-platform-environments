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
                "s3:*Object"
            ],
            "Resource": "arn:aws:s3:::dpr-*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::dpr-*"
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