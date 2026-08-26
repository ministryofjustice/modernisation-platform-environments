# Note that the actual Lambda function to remove automated snapshots was created manually on the Console

##################################
### IAM Role for BackUp Lambda
##################################

data "aws_iam_policy_document" "backup_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "ssm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup_lambda" {
  name               = "${local.application_name_short}-backup-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.backup_lambda.json
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-backup-lambda-role" }
  )
}

resource "aws_iam_policy" "backup_lambda" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name_short}-${local.environment}-backup-lambda-policy"
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-backup-lambda-policy" }
  )
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

resource "aws_iam_role_policy_attachment" "backup_lambda" {
  role       = aws_iam_role.backup_lambda.name
  policy_arn = aws_iam_policy.backup_lambda.arn
}


######################################
### Lambda Resources
######################################

resource "aws_security_group" "backup_lambda" {
  name        = "${local.application_name_short}-${local.environment}-backup-lambda-security-group"
  description = "Bakcup Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-backup-lambda-security-group" }
  )
}

######################################
### EventBridge Resources
######################################

resource "aws_cloudwatch_event_rule" "deletesnapshotFunction_mon_fri" {
  name                = "laa-deletesnapshotRule-${local.environment}-mp"
  description         = "Delete snapshots over 7 days old"
  schedule_expression = "cron(10 02 ? * MON-FRI *)"

  tags = merge(
    local.tags,
    { Name = "laa-deletesnapshotRule-${local.environment}-mp" }
  )
}

# Manually created in the CDC POC account console
data "aws_lambda_function" "delete_snapshots" {
  function_name = "delete_snapshots"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_mon_fri" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.delete_snapshots.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.deletesnapshotFunction_mon_fri.arn
}

resource "aws_cloudwatch_event_target" "deletesnapshotFunctioncheck_mon_fri" {
  rule = aws_cloudwatch_event_rule.deletesnapshotFunction_mon_fri.name
  arn  = data.aws_lambda_function.delete_snapshots.arn
}