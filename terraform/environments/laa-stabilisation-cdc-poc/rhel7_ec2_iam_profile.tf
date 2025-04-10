################################
# rhel7 EC2 Instance Profile 
################################

# IAM Role, policy and instance profile (to attach the role to the EC2)

resource "aws_iam_instance_profile" "rhel7" {
  name = "rhel7-ec2-instance-profile"
  role = aws_iam_role.rhel7.name
  tags = merge(
    local.tags,
    {
      Name = "rhel7-ec2-instance-profile"
    }
  )
}

resource "aws_iam_role" "rhel7" {
  name = "rhel7-ec2-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "rhel7-ec2-instance-role"
    }
  )
  path               = "/"
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

resource "aws_iam_policy" "rhel7" {
  name = "rhel7-ec2-service"
  tags = merge(
    local.tags,
    {
      Name = "rhel7-ec2-service"
    }
  )
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:CreateTags",
                "ec2:CreateSnapshots"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "rhel7" {
  role       = aws_iam_role.rhel7.name
  policy_arn = aws_iam_policy.rhel7.arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.rhel7.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}