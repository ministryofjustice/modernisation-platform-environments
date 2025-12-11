######################################
### EC2 IAM ROLE AND PROFILE
######################################
resource "aws_iam_instance_profile" "ec2_instance_profile_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  name = "${local.application_name}-ec2-profile"
  role = aws_iam_role.ec2_instance_role_new[0].name
}

resource "aws_iam_role" "ec2_instance_role_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  name               = "${local.application_name}-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_instance_role_attachment_new" {
  count      = contains(["test", "preproduction"], local.environment) ? 1 : 0
  role       = aws_iam_role.ec2_instance_role_new[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ec2_instance_policy_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name}-ec2-policy"
  role = aws_iam_role.ec2_instance_role_new[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001",
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ],
        Resource = [
          "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*",
        ]
      }
    ]
  })
}
