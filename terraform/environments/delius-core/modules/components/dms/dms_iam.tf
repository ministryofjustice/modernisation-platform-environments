data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}

resource "aws_iam_role" "dms-vpc-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-vpc-role"
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
}

# resource "aws_iam_role" "dms_remote_s3_endpoint_writer" {
#   assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
#   name               = "dms-remote-s3-endpoint-role"
# }

# data "aws_iam_policy_document" "dms_remote_s3_endpoint_writer" {
#   count      = try(var.dms_config.audit_target_endpoint.read_database.write_environment, null) == null ? 0 : 1
#   version = "2012-10-17"

#   statement {
#     sid       = "DMSS3EndpointPolicy"
#     effect    = "Allow"
#     actions   = ["s3:PutObject"]
#     resources = [var.dms_config.audit_target_endpoint.read_database.write_environment]

#     principals {
#       type        = "Service"
#       identifiers = ["dms.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role_policy" "dms_remote_s3_endpoint_writer_policy" {
#   name        = "dms-remote-s3-endpoint-writer-policy"
#   description = "Allow writing of DMS replication data to s3 bucket in another account"

#   policy      = data.aws_iam_policy_document.dms_remote_s3_endpoint_writer
# }

# resource "aws_iam_policy_attachment" "dms_remote_s3_endpoint_writer_policy_attachment" {
#   role       = aws_iam_role.dms_remote_s3_endpoint_writer.name
#   policy_arn = aws_iam_role_policy.dms_remote_s3_endpoint_writer_policy.arn
# }

# locals {
#    client_ids = 
# }


resource "aws_iam_role" "dms_clients_may_list_buckets" {
  name = "DMSListBuckets"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for principal in var.dms_config.client_account_arns:
      {
        Effect = "Allow",
        Principal = {
          AWS = principal
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# resource "aws_iam_role_policy" "assume_role_policy" {
#   provider = aws.target

#   name   = "AssumeRolePolicy"
#   role   = aws_iam_role.assume_role.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "s3:ListAllMyBuckets",
#           "s3:ListBucket"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# output "role_arn" {
#   value = aws_iam_role.assume_role.arn
# }

