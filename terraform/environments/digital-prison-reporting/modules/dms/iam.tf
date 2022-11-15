# Create a role that can be assummed by the root account
resource "aws_iam_role" "dmsvpcrole" {
  name = "dms-vpc-role"
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
resource "aws_iam_role_policy" "dmsvpcpolicy" {
  name = "dmsvpcpolicy"
  role = "${aws_iam_role.dmsvpcrole.id}"

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
  name = "dms-kenisis-endpoint-role"
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

#DMS Role with kinesis Write Access
resource "aws_iam_role_policy_attachment" "dms-kinesis-attachment" {
  role       = aws_iam_role.dms-kinesis-role.name
  policy_arn = var.kinesis_stream_policy
}

