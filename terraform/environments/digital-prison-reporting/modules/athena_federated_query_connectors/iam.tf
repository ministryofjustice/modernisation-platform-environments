# tflint-ignore-file: terraform_required_version, terraform_required_providers 

# The Connector Lambda will use this policy to access everything it needs
resource "aws_iam_policy" "athena_federated_query_connector_policy" {
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions.TO DO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083"

  name        = "${var.name}_policy"
  description = "The policy the connector will use"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      },
      {
        "Action" : [
          "cloudwatch:PutMetricData"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ]
      },
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:logs:${var.region}:${var.account_id}:*"
        ]
      },
      {
        "Action" : [
          "glue:GetTableVersions",
          "glue:GetPartitions",
          "glue:GetTables",
          "glue:GetTableVersion",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetPartition",
          "glue:GetDatabase"
        ],
        "Resource" : "arn:aws:glue:${var.region}:${var.account_id}:*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "athena:GetQueryExecution"
        ],
        "Resource" : "arn:aws:athena:${var.region}:${var.account_id}:*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:ListAllMyBuckets"
        ],
        "Resource" : "arn:aws:s3:::*",
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.spill_bucket_name}",
          "arn:aws:s3:::${var.spill_bucket_name}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : var.credentials_secret_arns,
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "kms:GenerateDataKey"
        ],
        "Resource" : [
          "arn:aws:kms:*:${var.account_id}:key/*"
        ],
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "athena_federated_query_lambda_execution_role" {

  name        = "${var.name}-execution-role"
  description = "Lambda will assume this role to run the connector"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "athena_federated_query_lambda_role_policy_attachment" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  policy_arn = aws_iam_policy.athena_federated_query_connector_policy.arn
  role       = aws_iam_role.athena_federated_query_lambda_execution_role.name
}
