# Database Migration Service requires the below IAM Roles to be created before replication instances can be created. 

# Define IAM role for DMS S3 Endpoint
resource "aws_iam_role" "dms_endpoint_role" {
  name               = "dms-endpoint-access-role-tf"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json

  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having DMS-Endpoint access policies",
    }
  )

}

# Define S3 IAM policy for DMS S3 Endpoint
resource "aws_iam_policy" "dms_ep_s3_role_policy" {
  name = "dms-s3-target-ep-policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AthenaDMS",
          "Effect" : "Allow",
          "Action" : [
            "athena:StartQueryExecution",
            "athena:GetQueryExecution",
            "athena:CreateWorkGroup"
          ],
          "Resource" : "arn:aws:athena:eu-west-2:${local.env_account_id}:workgroup/dms_validation_workgroup_for_task_*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "glue:CreateDatabase",
            "glue:DeleteDatabase",
            "glue:GetDatabase",
            "glue:GetTables",
            "glue:CreateTable",
            "glue:DeleteTable",
            "glue:GetTable"
          ],
          "Resource" : [
            "arn:aws:glue:eu-west-2:${local.env_account_id}:catalog",
            "arn:aws:glue:eu-west-2:${local.env_account_id}:database/aws_dms_s3_validation_*",
            "arn:aws:glue:eu-west-2:${local.env_account_id}:table/aws_dms_s3_validation_*/*",
            "arn:aws:glue:eu-west-2:${local.env_account_id}:userDefinedFunction/aws_dms_s3_validation_*/*"
          ]
        },
        {
          "Action" : [
            "s3:GetBucketLocation",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts"
          ],
          "Effect" : "Allow",
          "Resource" : [
            module.s3-dms-target-store-bucket.bucket.arn,
            module.s3-athena-bucket.bucket.arn,
            module.s3-dms-premigrate-assess-bucket.bucket.arn
          ],
          "Sid" : "DMSAccess"
        },
        {
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:ListBucketMultipartUploads",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${module.s3-dms-target-store-bucket.bucket.arn}/*",
            "${module.s3-athena-bucket.bucket.arn}/*",
            "${module.s3-dms-premigrate-assess-bucket.bucket.arn}/*"
          ],
          "Sid" : "DMSObjectActions"
        }
      ]
    }
  )
}


# Attach predefined IAM Policy to the Role for DMS S3 Endpoint
resource "aws_iam_role_policy_attachment" "dms_ep_s3_role_policy_attachment" {
  role       = aws_iam_role.dms_endpoint_role.name
  policy_arn = aws_iam_policy.dms_ep_s3_role_policy.arn
}

# -------------------------------------------------------------

resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  name                = "dms-cloudwatch-logs-role"
  assume_role_policy  = data.aws_iam_policy_document.dms_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"]
  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having DMS-Cloudwatch-Logs access policies",
    }
  )
}

# -------------------------------------------------------------

# Error: creating DMS Replication Subnet Group (rds-replication-subnet-group-tf): AccessDeniedFault: The IAM Role arn:aws:iam::############:role/dms-vpc-role is not configured properly.
resource "aws_iam_role" "dms_vpc_role" {
  name                = "dms-vpc-role"
  assume_role_policy  = data.aws_iam_policy_document.dms_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"]
  tags = merge(
    local.tags,
    {
      Resource_Type = "Role having DMS access policies",
    }
  )
}

# -------------------------------------------------------------
