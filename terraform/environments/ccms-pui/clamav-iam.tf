# ClamAV IAM Role

resource "aws_iam_role" "clamav_role" {
  name                 = "clamav-ec2-role"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  tags = merge(local.tags,
    { Name = lower(format("%s-clamav-%s-role", local.application_name, local.environment)) }
  )
}

# IAM Policy for ClamAV Logs to Cloudwatch
data "aws_iam_policy_document" "cloudwatch_logs_clamav" {
  statement {
    sid = "EnableCloudWatchLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.log_group_clamav_clamd.arn}*",
      "${aws_cloudwatch_log_group.log_group_clamav_freshclam.arn}:*",
    ]
  }
  statement {
    sid = "DescribeCloudWatchLogStreams"
    actions = [
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.log_group_clamav_clamd.arn,
      aws_cloudwatch_log_group.log_group_clamav_freshclam.arn,
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs_clamav" {
  name   = "${local.application_name}-clamav-cloudwatch-logs"
  role   = aws_iam_role.clamav_role.name
  policy = data.aws_iam_policy_document.cloudwatch_logs_clamav.json
}

# Attach SSM Policy to ClamAV Role
resource "aws_iam_role_policy_attachment" "ssm_policy_clamav" {
  role       = aws_iam_role.clamav_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for ClamAV EC2 Instance

resource "aws_iam_instance_profile" "iam_instace_profile_clamav" {
  name = "${local.application_name}-clamav-ec2-instance-profile"
  role = aws_iam_role.clamav_role.name
  path = "/"
  tags = merge(local.tags,
    { Name = lower(format("%s-clamav-%s-instance-profile", local.application_name, local.environment)) }
  )
}