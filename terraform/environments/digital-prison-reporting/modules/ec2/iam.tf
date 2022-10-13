resource "aws_iam_role" "kinesis-agent-instance-role" {
  name = "${var.name}-role"
  path = "/"

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

## Kines Data Stream Developer Policy
resource "aws_iam_policy" "kinesis-data-stream-developer" {
  name        = "${var.name}-developer"
  description = "Kinesis Data Stream Developer Policy"
  path        = "/"

  policy = data.aws_iam_policy_document.kinesis-data-stream.json
}

# Full list of Kinesis Stream Actions, https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonkinesis.html
data "aws_iam_policy_document" "kinesis-data-stream" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "kinesis:PutRecords",
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamConsumer",
      "kinesis:GetRecords",
      "kinesis:ListShards",
      "kinesis:ListStreamConsumers",
      "kinesis:ListStreams",
      "kinesis:GetRecords",
    ]
    resources = [
      "arn:aws:kinesis:eu-west-2:771283872747:stream/dpr-kinesis-data-domain-development",
      "arn:aws:kinesis:eu-west-2:771283872747:stream/dpr-kinesis-ingestor-development",
      "arn:aws:kinesis:eu-west-2:771283872747:stream/dpr-kinesis-data-demo-development"
    ]
  }
}

data "aws_iam_policy_document" "kinesis-cloudwatch-kms" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "kms:*",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_instance_profile" "kinesis-agent-instance-profile" {
  name = "${var.name}-profile"
  role = aws_iam_role.kinesis-agent-instance-role.name
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = aws_iam_policy.kinesis-data-stream-developer.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch-kms" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = aws_iam_policy.kinesis-cloudwatch-kms.arn
}

resource "aws_iam_policy_attachment" "this" {
  name       = "ssm_managed_instance_core"
  roles      = [aws_iam_role.kinesis-agent-instance-role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ec2-role-for-ssm" {
  name       = "ssm_managed_instance_ec2_role"
  roles      = [aws_iam_role.kinesis-agent-instance-role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy_attachment" "read_list_s3_access_attachment" {
  name       = "read_list_s3_access_attachment"
  roles      = [aws_iam_role.kinesis-agent-instance-role.name]
  policy_arn = var.s3_policy_arn
}
