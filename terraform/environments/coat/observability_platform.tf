module "observability_platform_tenant" {

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=fbbe5c8282786bcc0a00c969fe598e14f12eea9b" # v1.2.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-production"]

  tags = local.tags
}

resource "aws_iam_policy" "grafana_athena_full_access_policy" {

  # checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  # checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"

  name = "grafana_athena_full_access_policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "athena:*"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:GetTable",
                "glue:GetTables",
                "glue:GetPartition",
                "glue:GetPartitions",
                "glue:BatchGetPartition"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload",
                "s3:CreateBucket",
                "s3:PutObject",
                "s3:PutBucketPublicAccessBlock"
            ],
            "Resource": [ 
              "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
              "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
            ]
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "observability_platform_role_grafana_athena_full_access_attachment" {
  role       = "observability-platform"
  policy_arn = aws_iam_policy.grafana_athena_full_access_policy.arn
}