## SSM Specific
resource "aws_iam_policy" "ec2_ssm_policy" {
  name        = "ssm_ec2_policy-${local.component_name}"
  description = "Allows SSM Connect logging for Sandbox"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:eu-west-2::log-group:/aws/ssm/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:*"
          ],
          "Resource" : [
            "arn:aws:ssm:eu-west-2:767123802783:*"
          ]
        },
        {
          "Action" : "s3:GetObject",
          "Effect" : "Allow",
          "Resource" : [
            "arn:aws:s3:::patch-baseline-snapshot-eu-west-2/*",
            "arn:aws:s3:::eu-west-2-birdwatcher-prod/*",
            "arn:aws:s3:::aws-windows-downloads-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-document-attachments-eu-west-2/*",
            "arn:aws:s3:::aws-ssm-distributor-file-eu-west-2/*",
            "arn:aws:s3:::amazon-ssm-packages-eu-west-2/*",
            "arn:aws:s3:::amazon-ssm-eu-west-2/*"
          ]
        }
      ]
    }
  )
}

## Oracle EC2 Role
resource "aws_iam_role" "role_stsassume_oracle_base" {
  name                 = "role_stsassume_oracle_base_sandbox"
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
    { Name = lower(format("RoleSsm-%s-OracleBase", local.component_name)) }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_logging_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.ec2_ssm_policy.arn
}



resource "aws_iam_role_policy_attachment" "ssm_policy_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach Secrets Manager Policy to Role
resource "aws_iam_role_policy_attachment" "secrets_manager_policy_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "iam_instace_profile_ccms_base" {
  name = "iam_instace_profile_ccms_base_sandbox"
  role = aws_iam_role.role_stsassume_oracle_base.name
  path = "/"
  tags = merge(local.tags,
    { Name = lower(format("IamProfile-%s-OracleBase", local.component_name)) }
  )
}

# Cloudwatch Logging
resource "aws_iam_policy" "cw_logging_policy" {
  name        = "cw_log_policy-${local.component_name}"
  description = "Allows EC2 CW logging for Sandbox"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:*:*:*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "cw_logging_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.cw_logging_policy.arn
}

# RMAN policy
resource "aws_iam_policy" "rman_to_s3" {
  name        = "ec2_to_s3_policy-${local.component_name}"
  description = "Allows EC2 to write to S3 for Sandbox"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetBucketLocation",
            "s3:ListAllMyBuckets"
          ],
          "Resource" : "arn:aws:s3:::*"
        },
        {
          "Effect" : "Allow",
          "Action" : ["s3:ListBucket"],
          "Resource" : [
            "arn:aws:s3:::ccms-ebs-${local.component_name}-dbbackup",
            "arn:aws:s3:::ccms-ebs-${local.component_name}-dbbackup/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject"
          ],
          "Resource" : [
            "arn:aws:s3:::ccms-ebs-${local.component_name}-dbbackup",
            "arn:aws:s3:::ccms-ebs-${local.component_name}-dbbackup/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "rman_to_s3_policy" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.rman_to_s3.arn
}

# # Oracle Licensing policy
# resource "aws_iam_policy" "oracle_licensing" {
#   name        = "oracle_licensing_policy-${local.component_name}"
#   description = "Allows licensing metrics to be captured for Sandbox"

#   policy = jsonencode(
#     {
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Action" : [
#             "s3:PutObject",
#             "s3:GetObject",
#             "s3:PutObjectAcl",
#             "s3:ListBucket",
#             "s3:DeleteObject"
#           ],
#           "Resource" : [
#             "arn:aws:s3:::license-manager-artifact-bucket/*",
#             "arn:aws:s3:::license-manager-artifact-bucket"
#           ],
#           "Effect" : "Allow",
#           "Sid" : "SSMS3BucketPolicy"
#         }
#       ]
#     }
#   )
# }

# resource "aws_iam_role_policy_attachment" "oracle_licensing_policy" {
#   role       = aws_iam_role.role_stsassume_oracle_base.name
#   policy_arn = aws_iam_policy.oracle_licensing.arn
# }

# # Access to LZ buckets.
# resource "aws_iam_policy" "access_to_lz_buckets" {
#   name        = "access_to_lz_buckets-${local.environment}"
#   description = "Allows licensing metrics to be captured"

#   policy = jsonencode(
#     {
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Sid" : "AccessToLZBuckets",
#           "Effect" : "Allow",
#           "Action" : [
#             "s3:DeleteObject",
#             "s3:GetObject",
#             "s3:ListBucket",
#             "s3:PutObject"
#           ],
#           "Resource" : [
#             "arn:aws:s3:::laa-ccms-inbound-*",
#             "arn:aws:s3:::laa-ccms-outbound-*"
#           ]
#         }
#       ]
#     }
#   )
# }

# resource "aws_iam_role_policy_attachment" "access_to_lz_buckets_policy" {
#   role       = aws_iam_role.role_stsassume_oracle_base.name
#   policy_arn = aws_iam_policy.access_to_lz_buckets.arn
# }

# Allow EC2 operations.
resource "aws_iam_policy" "ec2_operations_policy" {
  name        = "ec2_operations-${local.component_name}"
  description = "Allows EC2 operations for Sandbox"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "EC2Operations",
          "Effect" : "Allow",
          "Action" : [
            "ec2:Describe*",
            "ec2:CreateSnapshot",
            "ec2:CreateSnapshots",
            "ec2:DeleteSnapshot",
            "ec2:CreateTags",
            "ec2:DeleteTags"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ec2_operations_policy_att" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.ec2_operations_policy.arn
}

# S3 shared bucket

data "aws_iam_policy_document" "ccms_ebs_shared_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:CopyObject",
      "s3:DeleteObject",
      "s3:DeleteObjects",
      "s3:GetObject",
      "s3:ListObjects",
      "s3:ListObjectsV2",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.ccms_ebs_shared.arn,
      "${aws_s3_bucket.ccms_ebs_shared.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ccms_ebs_shared_s3" {
  description = "Policy to allow operations in ${aws_s3_bucket.ccms_ebs_shared.id}"
  name        = "ccms_ebs_shared_s3-${local.component_name}"
  policy      = data.aws_iam_policy_document.ccms_ebs_shared_s3.json
}

resource "aws_iam_role_policy_attachment" "ccms_ebs_shared_s3" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = aws_iam_policy.ccms_ebs_shared_s3.arn
}
