locals {
  current_account_id                = data.aws_caller_identity.current.account_id
  current_account_region            = data.aws_region.current.name
  setup_datamart                    = local.application_data.accounts[local.environment].setup_redshift
  dms_iam_role_permissions_boundary = null
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
}

# Resuse for all S3 read Only
# S3 Read Only Policy
resource "aws_iam_policy" "s3_read_access_policy" {
  name = "dpr_s3_read_policy"
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

# KMS Read/Decrypt Policy
resource "aws_iam_policy" "kms_read_access_policy" {
  name = "dpr_kms_read_policy"
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
  name  = "${local.project}-redshift-cluster-role"

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
  name  = "${local.project}-redshift-spectrum-role"

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
    "arn:aws:iam::${var.account}:policy/${aws_iam_policy.s3_read_access_policy.name}",
    "arn:aws:iam::${var.account}:policy/${aws_iam_policy.kms_read_access_policy.name}",
    "arn:aws:iam::${var.account}:policy/${aws_iam_policy.redshift_spectrum_policy.name}"
  ])

  role = aws_iam_role.redshift-spectrum-role.name
  policy_arn = each.value
}