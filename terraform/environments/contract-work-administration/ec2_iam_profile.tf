################################
# CWA EC2 Instance Profile 
################################

# IAM Role, policy and instance profile (to attach the role to the EC2)

resource "aws_iam_instance_profile" "cwa" {
  name = "${local.application_name}-ec2-instance-profile"
  role = aws_iam_role.cwa.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-profile"
    }
  )
}

resource "aws_iam_role" "cwa" {
  name = "${local.application_name}-ec2-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-instance-role"
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

resource "aws_iam_policy" "cwa" {
  name = "${local.application_name}-ec2-service"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-service"
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
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:cwa/app/*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect":"Allow",
            "Action":[
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:DeleteObject"
            ],
            "Resource":"arn:aws:s3:::${aws_s3_bucket.scripts.id}/*-cw-custom.sh"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.cwa.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cwa" {
  role       = aws_iam_role.cwa.name
  policy_arn = aws_iam_policy.cwa.arn
}

################################
# SMTP EC2 Instance Profile 
################################

resource "aws_iam_instance_profile" "smtp" {
  name = "${local.application_name}-smtp-instance-profile"
  role = aws_iam_role.smtp.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-smtp-instance-profile"
    }
  )
}

resource "aws_iam_role" "smtp" {
  name = "${local.application_name}-smtp-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-smtp-instance-role"
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

resource "aws_iam_policy" "smtp" {
  name = "${local.application_name}-smtp-iam-policy"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-smtp-iam-policy"
    }
  )
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutRetentionPolicy",
                "logs:PutLogEvents",
                "ec2:DescribeInstances"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:postfix/app/*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "smtp" {
  role       = aws_iam_role.smtp.name
  policy_arn = aws_iam_policy.smtp.arn
}

resource "aws_iam_role_policy_attachment" "smtp_ssm" {
  role       = aws_iam_role.smtp.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}