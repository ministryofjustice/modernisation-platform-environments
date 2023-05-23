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
        },
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "dms.amazonaws.com"
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
      "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/dpr-kinesis-data-domain-development",
      "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/dpr-kinesis-ingestor-development",
      "arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.current.account_id}:stream/dpr-kinesis-data-demo-development"
    ]
  }
}

## Kines Data Stream CW and KMS Policy
resource "aws_iam_policy" "kinesis-cw-kms-developer" {
  name        = "${var.name}-cw-kms-developer"
  description = "Kinesis Data Stream CW KMS Developer Policy"
  path        = "/"

  policy = data.aws_iam_policy_document.kinesis-cloudwatch-kms.json
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

## DMS Policy
resource "aws_iam_policy" "dms" {
  name        = "${var.name}-dms-service-access"
  description = "DMS Service Access Policy"
  path        = "/"

  policy = data.aws_iam_policy_document.dms.json
}

data "aws_iam_policy_document" "dms" {
  statement {
    actions = [
      "dms:StartReplicationTask",
      "dms:StopReplicationTask",
      "dms:TestConnection",
      "dms:StartReplicationTaskAssessment",
      "dms:StartReplicationTaskAssessmentRun",
      "dms:DescribeEndpoints",
      "dms:DescribeEndpointSettings",
      "dms:RebootReplicationInstance",
      "athena:*",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:*Object*",
      "s3:PutObjectTagging",
      "s3:GetBucketLocation",
    ]
    resources = [
      "arn:aws:s3:::dpr-*/*",
      "arn:aws:s3:::dpr-*"
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "s3:ListAccessPoints",
      "s3:ListJobs",
      "s3:ListObjects",  
    ]
    resources = [
      "*"
    ]
  } 

  statement {
    actions = [
      "iam:GetRole",
      "iam:PassRole",
      "iam:CreateRole",
      "iam:AttachRolePolicy",
    ]
    resources = ["*"]   
  } 
}

## Glue Access Policy
resource "aws_iam_policy" "glue-full-access" {
  name        = "${var.name}-glue-admin"
  description = "Glue Full Policy"
  path        = "/"

  policy = data.aws_iam_policy_document.glue-access.json
}

## Glue Access Policy Document
data "aws_iam_policy_document" "glue-access" {
  statement {
    actions = [
      "glue:*",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::*:role/AWSGlueServiceRole*"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"

      values = [
        "glue.amazonaws.com"
      ]
    }
  }

  statement {
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::*:role/service-role/AWSGlueServiceRole*"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"

      values = [
        "glue.amazonaws.com"
      ]
    }
  }
}

## Dynamo Access Policy
resource "aws_iam_policy" "dynamodb-access" {
  name        = "${var.name}-dynamodb-access"
  description = "Dynamo DB Access Policy"
  path        = "/"

  policy = data.aws_iam_policy_document.dynamo-access.json
}

## DynamoDB Access Policy Document
data "aws_iam_policy_document" "dynamo-access" {
  statement {
    sid = "DynamoDBTableAccess"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem"
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account}:table/*"
    ]
  }

  statement {
    sid = "DynamoDBIndexAndStreamAccess"
    actions = [
      "dynamodb:GetShardIterator",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:ListStreams"
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account}:table/*/index/*",
      "arn:aws:dynamodb:${var.region}:${var.account}:table/*/stream/*"    ]
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

resource "aws_iam_role_policy_attachment" "glue-access" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = aws_iam_policy.glue-full-access.arn
}

resource "aws_iam_role_policy_attachment" "dynamo-access" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = aws_iam_policy.dynamodb-access.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch-kms" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = aws_iam_policy.kinesis-cw-kms-developer.arn
}

resource "aws_iam_role_policy_attachment" "dms" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = aws_iam_policy.dms.arn
}

data "aws_iam_policy" "RedshiftQueryEditor" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftQueryEditorV2FullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift-queryeditor" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = data.aws_iam_policy.RedshiftQueryEditor.arn
}

data "aws_iam_policy" "AmazonRedshiftFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift-admin" {
  role       = aws_iam_role.kinesis-agent-instance-role.name
  policy_arn = data.aws_iam_policy.AmazonRedshiftFullAccess.arn
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

# TBC
#resource "aws_iam_policy_attachment" "read_list_s3_access_attachment" {
#  name       = "read_list_s3_access_attachment"
#  roles      = [aws_iam_role.kinesis-agent-instance-role.name]
#  policy_arn = var.s3_policy_arn
#}
