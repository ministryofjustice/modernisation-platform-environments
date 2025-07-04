data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# Define IAM role for DMS S3 Endpoint
resource "aws_iam_role" "dms_spike_s3_access_role" {
  name = "${var.dms_instance_id}-dms-s3-access"
  assume_role_policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Principal = {
            Service = "dms.amazonaws.com"
          },
          Action = "sts:AssumeRole"
        }
      ]
    }
  )
}

# Define S3 IAM policy for DMS S3 Endpoint
resource "aws_iam_policy" "dms_spike_s3_write_policy" {
  name = "${var.dms_instance_id}-write"

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
          "Resource" : "arn:aws:athena:eu-west-2:${var.env_account_id}:workgroup/dms_validation_workgroup_for_task_*"
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
            "arn:aws:glue:eu-west-2:${var.env_account_id}:catalog",
            "arn:aws:glue:eu-west-2:${var.env_account_id}:database/aws_dms_s3_validation_*",
            "arn:aws:glue:eu-west-2:${var.env_account_id}:table/aws_dms_s3_validation_*/*",
            "arn:aws:glue:eu-west-2:${var.env_account_id}:userDefinedFunction/aws_dms_s3_validation_*/*"
          ]
        },
        {
          "Sid" : "DMSAccess"
          "Action" : [
            "s3:GetBucketLocation",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts"
          ],
          "Effect" : "Allow",
          "Resource" : [
            var.s3_bucket_arn,
            "${var.s3_bucket_arn}/*"
          ],
        },
        {
          "Sid" : "DMSObjectActions"
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
            var.s3_bucket_arn,
            "${var.s3_bucket_arn}/*"

          ],
        },
        {
          "Sid" : "CloudWatchLogs"
          "Effect" : "Allow"
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          "Resource" : [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/dms*",
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/dms*:log-stream:*",
          ]

        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_dms_spike_s3_policy" {
  role       = aws_iam_role.dms_spike_s3_access_role.name
  policy_arn = aws_iam_policy.dms_spike_s3_write_policy.arn
}