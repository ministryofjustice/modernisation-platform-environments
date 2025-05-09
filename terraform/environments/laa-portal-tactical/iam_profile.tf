########################################################################
# EC2 Instance Profile - used for all of OAM, OIM, OHS and IDM
########################################################################

# IAM Role, policy and instance profile (to attach the role to the EC2)

resource "aws_iam_instance_profile" "portal" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.portal.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

resource "aws_iam_role" "portal" {
  name = "${local.application_name}-ec2-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-role"
    }
  )
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

# TODO What exactly do the instance role require kms:Decrypt for?

resource "aws_iam_policy" "portal" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-instance-policy"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-policy"
    }
  )
  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "ec2messages:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:UpdateInstanceInformation",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:ListInstanceAssociations",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:DescribeAssociation",
                "ssm:GetManifest",
                "ssm:ListAssociations",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "portal" {
  role       = aws_iam_role.portal.name
  policy_arn = aws_iam_policy.portal.arn
}