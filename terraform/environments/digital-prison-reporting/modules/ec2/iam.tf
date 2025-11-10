# tflint-ignore-file: Terraform_required_version, terraform_required_providers

resource "aws_iam_role" "bastion-host-instance-role" {
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

## DMS Policy
resource "aws_iam_policy" "dms" {
  name        = "${var.name}-dms-service-access"
  description = "DMS Service Access Policy"
  path        = "/"

  policy = data.aws_iam_policy_document.dms.json
}

data "aws_iam_policy_document" "dms" {
  #checkov:skip=CKV_AWS_111:"Ensure IAM policies does not allow write access without constraints, Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_109:"Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_356:"Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions. Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"

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
      "arn:aws:s3:::dpr-*",
      "arn:aws:s3:::dpr-*/*"
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
  #checkov:skip=CKV_AWS_110:"Ensure IAM policies does not allow privilege escalation. Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_111:"Ensure IAM policies does not allow write access without constraints.Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_109:"Ensure IAM policies does not allow permissions management/resource exposure without constraints. Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_356:"Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions. Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"

  statement {
    actions = [
      "glue:*"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:List*"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:*"
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

## EC2 Generic Role
resource "aws_iam_policy" "generic" {
  name        = "${var.name}-generic-policy"
  description = "AWS Generic Policy for EC2 Agent"
  path        = "/"

  policy = data.aws_iam_policy_document.generic.json
}

data "aws_iam_policy_document" "generic" {
  #checkov:skip=CKV_AWS_111:"Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_AWS_109:"Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_107:"Ensure IAM policies does not allow credentials exposure. Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  #checkov:skip=CKV_AWS_356:"Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions. Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"
  statement {
    actions = [
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:List*",
      "ec2:AssignPrivateIpAddresses",
    ]
    resources = [
      "*"
    ]
  }

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
    "arn:aws:dynamodb:${var.region}:${var.account}:table/*/stream/*"]
  }
}

resource "aws_iam_role_policy_attachment" "generic" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = aws_iam_policy.generic.arn
}

resource "aws_iam_instance_profile" "bastion-host-instance-profile" {
  name = "${var.name}-profile"
  role = aws_iam_role.bastion-host-instance-role.name
}

resource "aws_iam_role_policy_attachment" "glue-access" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = aws_iam_policy.glue-full-access.arn
}

resource "aws_iam_role_policy_attachment" "dynamo-access" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = aws_iam_policy.dynamodb-access.arn
}

resource "aws_iam_role_policy_attachment" "dms" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = aws_iam_policy.dms.arn
}

data "aws_iam_policy" "RedshiftQueryEditor" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftQueryEditorV2FullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift-queryeditor" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = data.aws_iam_policy.RedshiftQueryEditor.arn
}

data "aws_iam_policy" "AmazonRedshiftFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift-admin" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = data.aws_iam_policy.AmazonRedshiftFullAccess.arn
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-core" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-ssm" {
  role       = aws_iam_role.bastion-host-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# TBC
#resource "aws_iam_policy_attachment" "read_list_s3_access_attachment" {
#  name       = "read_list_s3_access_attachment"
#  roles      = [aws_iam_role.bastion-host-instance-role.name]
#  policy_arn = var.s3_policy_arn
#}
