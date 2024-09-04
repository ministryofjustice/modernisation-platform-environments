#DMS S3 Endpoint role
resource "aws_iam_role" "dms-s3-role" {
  name = "dms-${var.short_name}-s3-endpoint-role"
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
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  #checkov:skip=CKV_AWS_289: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_288: "Ensure IAM policies does not allow data exfiltration"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  #checkov:skip=CKV_AWS_289: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"


  name = "dms-${var.short_name}-s3-target-policy"

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
  role       = aws_iam_role.dms-s3-role.name
  policy_arn = aws_iam_policy.dms-s3-target-policy.arn
}

#DMS Operation s3 target role
resource "aws_iam_role" "dms-operator-s3-target-role" {
  name = "dms-${var.short_name}-operator-s3-target-role"
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
  #checkov:skip=CKV_AWS_290:TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions.TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"

  name = "dms-${var.short_name}-operator-s3-target-policy"

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
                "arn:aws:s3::*:dpr-*/*",
                "arn:aws:s3::*:dpr-*"
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
  role       = aws_iam_role.dms-operator-s3-target-role.name
  policy_arn = aws_iam_policy.dms-operator-s3-policy.arn
}