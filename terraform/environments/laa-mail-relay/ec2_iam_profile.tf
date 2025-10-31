
################################
# SMTP EC2 Instance Profile 
################################

resource "aws_iam_instance_profile" "smtp" {
  name = "${local.application_name}-instance-profile"
  role = aws_iam_role.smtp.name
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-instance-profile"
    }
  )
}

resource "aws_iam_role" "smtp" {
  name = "${local.application_name}-instance-role"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-instance-role"
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
  name = "${local.application_name}-iam-policy"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-iam-policy"
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