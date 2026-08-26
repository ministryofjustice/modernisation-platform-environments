data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "ssm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backuplambdarole" {
  name               = "apex-backuplambdarole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}



resource "aws_iam_policy" "backuplambdapolicy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name   = var.backup_policy_name
  tags   = var.tags
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement": [
        {
            "Action": [
                "lambda:InvokeFunction",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeInstances",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "s3:*",
                "ssm:*",
                "ses:*",
                "logs:*",
                "cloudwatch:*",
                "sts:AssumeRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "backuppolicyattachment" {
  role       = aws_iam_role.backuplambdarole.name
  policy_arn = aws_iam_policy.backuplambdapolicy.arn
}

