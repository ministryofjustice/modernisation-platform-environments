locals {
  current_account_id                = data.aws_caller_identity.current.account_id
  current_account_region            = data.aws_region.current.name
  setup_datamart                    = local.application_data.accounts[local.environment].setup_redshift
  dms_iam_role_permissions_boundary = null
}

# APIGateway Get Policy
resource "aws_iam_policy" "apigateway_get" {
  name = "${local.project}_apigateway_get_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "APIGatewayGETPermissions",
        "Action" : ["apigateway:GET"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:apigateway:${local.current_account_region}::/apis/*"]
      }
    ]
  })
}

## Glue DB Default Policy
resource "aws_glue_resource_policy" "glue_policy" {
  policy = data.aws_iam_policy_document.glue-policy-data.json
}

data "aws_iam_policy_document" "glue-policy-data" {
  statement {
    actions = [
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateSchema",
      "glue:DeleteSchema",
      "glue:UpdateTable",
    ]
    resources = ["arn:aws:glue:${local.current_account_region}:${local.current_account_id}:*"]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }

  statement {
    # Required for cross-account sharing via LakeFormation if producer has existing Glue policy
    # ref: https://docs.aws.amazon.com/lake-formation/latest/dg/hybrid-cross-account.html
    effect = "Allow"

    actions = [
      "glue:ShareResource"
    ]

    principals {
      type        = "Service"
      identifiers = ["ram.amazonaws.com"]
    }
    resources = [
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/*/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:catalog"
    ]
  }
}

# Resuse for all S3 read Only
# S3 Read Only Policy
resource "aws_iam_policy" "s3_read_access_policy" {
  name = local.s3_read_access_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowUserToSeeBucketListInTheConsole",
        "Action" : ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:List*",
          "s3:Get*",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.project}-*/*",
          "arn:aws:s3:::${local.project}-*"
        ]
      }
    ]
  })
}

# S3 Read Write Policy
resource "aws_iam_policy" "s3_read_write_policy" {
  name = local.s3_read_write_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowUserToSeeBucketListInTheConsole",
        "Action" : ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.project}-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*Object",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.project}-*/*",
          "arn:aws:s3:::${local.project}-*"
        ]
      }
    ]
  })
}

# S3 All Object Actions Policy
resource "aws_iam_policy" "s3_all_object_actions_policy" {
  name = local.s3_all_object_actions_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllObjectActions",
        "Action" : ["s3:*Object"],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${local.project}-*/*",
          "arn:aws:s3:::${local.project}-*"
        ]
      }
    ]
  })
}

# Invoke Lambda Policy
resource "aws_iam_policy" "invoke_lambda_policy" {
  name = local.invoke_lambda_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "arn:aws:lambda:*:${local.account_id}:function:*",
          "arn:aws:lambda:*:${local.account_id}:function:*:*"
        ]
      }
    ]
  })
}

# Start DMS Task Policy
resource "aws_iam_policy" "start_dms_task_policy" {
  name = local.start_dms_task_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "dms:*"
        ],
        "Resource" : [
          "arn:aws:dms:${local.account_region}:${local.account_id}:task:*"
        ]
      }
    ]
  })
}

# Trigger Glue Job Policy
resource "aws_iam_policy" "trigger_glue_job_policy" {
  name = local.trigger_glue_job_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ],
        "Resource" : [
          "arn:aws:glue:${local.account_region}:${local.account_id}:*"
        ]
      }
    ]
  })
}

# DynamoDB Access Policy
resource "aws_iam_policy" "dynamodb_access_policy" {
  name = local.dynamo_db_access_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DynamoDBTableAccess",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:dynamodb:*:*:table/dpr-*"
        ]
      }
    ]
  })
}

# State Machine Access Policy
resource "aws_iam_policy" "all_state_machine_policy" {
  name = local.all_state_machine_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "StateMachineAllAccess",
        "Action" : "states:*",
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}

# KMS Read/Decrypt Policy
resource "aws_iam_policy" "kms_read_access_policy" {
  name = local.kms_read_access_policy
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ],
        "Resource" : [
          "arn:aws:kms:*:${local.account_id}:key/*"
        ]
      }
    ]
  })
}

### Iam Role for AWS Redshift
# Amazon Redshift supports only identity-based policies (IAM policies).

resource "aws_iam_role" "redshift-role" {
  #  count = local.setup_datamart ? 1 : 0
  name = "${local.project}-redshift-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Principal = {
          "Service" = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      name    = "redshift-service-role"
      project = "dpr"
    }
  )
}

# Amazon Redshift supports only identity-based policies (IAM policies).
data "aws_iam_policy_document" "redshift-additional-policy" {
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
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:PutRetentionPolicy"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/redshift/*"
    ]
  }
  statement {
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "additional-policy" {
  name        = "dpr-redshift-policy"
  description = "Extra Policy for AWS Redshift"
  policy      = data.aws_iam_policy_document.redshift-additional-policy.json
}

resource "aws_iam_role_policy_attachment" "redshift" {
  role       = aws_iam_role.redshift-role.name
  policy_arn = aws_iam_policy.additional-policy.arn
}

### DMS Roles
# Create a role that can be assummed by the root account
data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }

  }
}

# CW Logs Role
# DMS CloudWatch Logs
resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  name                  = "dms-cloudwatch-logs-role"
  description           = "DMS IAM role for CloudWatch logs permissions"
  permissions_boundary  = local.dms_iam_role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.dms_assume_role.json
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"]
  force_detach_policies = true

  tags = merge(
    local.tags,
    {
      name    = "dms-service-cw-role"
      project = "dpr"
    }
  )
}

# DMS VPC
resource "aws_iam_role" "dmsvpcrole" {
  name                  = "dms-vpc-role"
  description           = "DMS IAM role for VPC permissions"
  permissions_boundary  = local.dms_iam_role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.dms_assume_role.json
  managed_policy_arns   = ["arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"]
  force_detach_policies = true

  tags = merge(
    local.tags,
    {
      name    = "dms-service-vpc-role"
      project = "dpr"
    }
  )
}

# Attach an admin policy to the role -- Evaluate if this is required
resource "aws_iam_role_policy" "dmsvpcpolicy" {
  name = "dms-vpc-policy"
  role = aws_iam_role.dmsvpcrole.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DeleteNetworkInterface",
                "ec2:ModifyNetworkInterfaceAttribute"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

### Iam User Role for AWS Redshift Spectrum,
resource "aws_iam_role" "redshift-spectrum-role" {
  name = "${local.project}-redshift-spectrum-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Principal = {
          "Service" = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      name    = "redshift-spectrum-role"
      project = "dpr"
    }
  )
}

data "aws_iam_policy_document" "redshift_spectrum" {
  statement {
    actions = [
      "glue:BatchCreatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:DeleteDatabase",
      "glue:GetTables",
      "glue:GetPartitions",
      "glue:BatchDeletePartition",
      "glue:UpdateTable",
      "glue:BatchGetPartition",
      "glue:DeleteTable",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition",
      "glue:CreateDatabase",
      "glue:BatchDeleteTable",
      "glue:CreatePartition",
      "glue:DeletePartition",
      "glue:UpdatePartition"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "redshift_spectrum_policy" {
  name        = "${local.project}-redshift-spectrum-policy"
  description = "Extra Policy for AWS Redshift Spectrum"
  policy      = data.aws_iam_policy_document.redshift_spectrum.json
}

resource "aws_iam_role_policy_attachment" "redshift_spectrum" {
  for_each = toset([
    "arn:aws:iam::${local.account_id}:policy/${aws_iam_policy.s3_read_write_policy.name}",
    "arn:aws:iam::${local.account_id}:policy/${aws_iam_policy.kms_read_access_policy.name}",
    "arn:aws:iam::${local.account_id}:policy/${aws_iam_policy.redshift_spectrum_policy.name}"
  ])

  role       = aws_iam_role.redshift-spectrum-role.name
  policy_arn = each.value
}

# Additional policy to allow execution of preview queries.
data "aws_iam_policy_document" "domain_builder_preview" {
  statement {
    actions = [
      "athena:GetQueryExecution",
      "athena:StartQueryExecution",
      "glue:GetDatabase",
      "glue:GetTable",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "domain_builder_preview_policy" {
  name        = "${local.project}-domain-builder-preview-policy"
  description = "Additional policy to allow execution of query previews in Athena"
  policy      = data.aws_iam_policy_document.domain_builder_preview.json
}

# Additional policy to allow execution of publish requests.
data "aws_iam_policy_document" "domain_builder_publish" {
  statement {
    actions = [
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "domain_builder_publish_policy" {
  name        = "${local.project}-domain-builder-publish-policy"
  description = "Additional policy to allow execution of query publish in Athena"
  policy      = data.aws_iam_policy_document.domain_builder_publish.json
}

## Redshift DataAPI Policy Document
# Policy Document
data "aws_iam_policy_document" "redshift_dataapi" {
  statement {
    actions = [
      "redshift-data:ListTables",
      "redshift-data:DescribeTable",
      "redshift-data:ListSchemas",
      "redshift-data:ListDatabases",
      "redshift-data:ExecuteStatement",
      "redshift-data:BatchExecuteStatement"
    ]
    resources = [
      "arn:aws:redshift:${local.account_region}:${local.account_id}:cluster:*"
    ]
  }

  statement {
    actions = [
      "redshift-data:GetStatementResult",
      "redshift-data:DescribeStatement",
      "redshift-data:ListStatements",
      "redshift-data:CancelStatement"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:aws:secretsmanager:${local.account_region}:${local.account_id}:secret:*"
    ]
  }

  statement {
    actions = [
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "*"
    ]
  }

}

# Redshift DataAPI Policy
resource "aws_iam_policy" "redshift_dataapi_cross_policy" {
  name        = "${local.project}-redshift-data-api-cross-policy"
  description = "Extra Policy for AWS Redshift"
  policy      = data.aws_iam_policy_document.redshift_dataapi.json
}


## Athena API Policy Document
# Policy Document
data "aws_iam_policy_document" "athena_api" {
  statement {
    actions = [
      "athena:GetDataCatalog",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${local.account_region}:${local.account_id}:*/*"
    ]
  }

  statement {
    actions = [
      "athena:ListWorkGroups"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${local.account_region}:${local.account_id}:function:dpr-athena-federated-query-oracle-function"
    ]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::dpr-*/*"
    ]
  }

  statement {
    actions = [
      "kms:GenerateDataKey"
    ]
    resources = [
      "arn:aws:kms:*:771283872747:key/*"
    ]
  }

}

# Athena API Policy
resource "aws_iam_policy" "athena_api_cross_policy" {
  name        = "${local.project}-athena-api-cross-policy"
  description = "Extra Policy for AWS Athena"
  policy      = data.aws_iam_policy_document.athena_api.json
}

## Glue Catalog ReadOnly
# Policy Document
data "aws_iam_policy_document" "glue_catalog_readonly" {
  statement {
    effect = "Allow"
    actions = [
      "glue:Get*",
      "glue:List*",
      "glue:DeleteTable",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:catalog",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:schema/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/*/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/*"
    ]
  }
  statement {
    effect = "Deny"
    actions = [
      "glue:DeleteDatabase",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:UpdateTable"
    ]
    resources = [
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/raw_archive",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/raw_archive/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/curated",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/curated/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/raw",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/raw/*",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/structured",
      "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/structured/*"
    ]
  }
}

# Athena API Policy
resource "aws_iam_policy" "glue_catalog_readonly" {
  name        = "${local.project}-glue-catalog-readonly"
  description = "Glue Catalog Readonly Policy"
  policy      = data.aws_iam_policy_document.glue_catalog_readonly.json
}

# Analytical Platform Share Policy & Role

data "aws_iam_policy_document" "analytical_platform_share_policy" {
  for_each = local.analytical_platform_share

  statement {
    effect = "Allow"
    actions = [
      "lakeformation:GrantPermissions",
      "lakeformation:RevokePermissions",
      "lakeformation:BatchGrantPermissions",
      "lakeformation:BatchRevokePermissions",
      "lakeformation:RegisterResource",
      "lakeformation:DeregisterResource",
      "lakeformation:ListPermissions",
      "lakeformation:DescribeResource",

    ]
    resources = [
      "arn:aws:lakeformation:${local.current_account_region}:${local.current_account_id}:catalog:${local.current_account_id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${local.current_account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"
    ]
  }
  # Needed for LakeFormationAdmin to check the presense of the Lake Formation Service Role
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRolePolicy",
      "iam:GetRole"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ram:CreateResourceShare",
      "ram:DeleteResourceShare"
    ]
    resources = [
      "arn:aws:ram:${local.current_account_region}:${local.current_account_id}:resource-share/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetPartition"
    ]
    resources = flatten([
      for resource in each.value.resource_shares : [
        "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:database/${resource.glue_database}",
        formatlist("arn:aws:glue:${local.current_account_region}:${local.current_account_id}:table/${resource.glue_database}/%s", resource.glue_tables),
        "arn:aws:glue:${local.current_account_region}:${local.current_account_id}:catalog"
      ]
    ])
  }
}

resource "aws_iam_role" "analytical_platform_share_role" {
  for_each = local.analytical_platform_share

  name = "${each.value.target_account_name}-share-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # In case consumer has a central location for terraform state storage that isn't the target account.
          AWS = "arn:aws:iam::${try(each.value.assume_account_id, each.value.target_account_id)}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "analytical_platform_share_policy_attachment" {
  for_each = local.analytical_platform_share

  name   = "${each.value.target_account_name}-share-policy"
  role   = aws_iam_role.analytical_platform_share_role[each.key].name
  policy = data.aws_iam_policy_document.analytical_platform_share_policy[each.key].json
}

# ref: https://docs.aws.amazon.com/lake-formation/latest/dg/cross-account-prereqs.html
resource "aws_iam_role_policy_attachment" "analytical_platform_share_policy_attachment" {
  for_each = local.analytical_platform_share

  role       = aws_iam_role.analytical_platform_share_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationCrossAccountManager"
}