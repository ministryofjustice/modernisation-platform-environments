### S3 BUCKET FOR WORKSPACES WEB SESSION LOGGING

moved {
  from = module.s3_bucket_workspacesweb_session_logs
  to   = module.s3_bucket_workspacesweb_session_logs[0]
}

module "s3_bucket_workspacesweb_session_logs" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}"
  force_destroy = true

  # Versioning
  versioning = {
    enabled = true
  }

  # Server side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.workspacesweb_session_logs[0].arn
      }
    }
  }

  # Public access block
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle configuration
  lifecycle_rule = [{
    id     = "session_logs_lifecycle"
    status = "Enabled"

    expiration = {
      days = 365
    }

    noncurrent_version_expiration = {
      days = 30
    }
  }]

  # Bucket policy using the IAM policy document
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_bucket_policy[0].json

  tags = merge(
    local.tags,
    {
      Name = "laa-workspacesweb-session-logs"
    }
  )
}

moved {
  from = random_string.bucket_suffix
  to   = random_string.bucket_suffix[0]
}

resource "random_string" "bucket_suffix" {
  count = local.create_resources ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  count = local.create_resources ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["workspaces-web.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}",
      "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}/*"
    ]
  }
}

### S3 BUCKET FOR SECURE BROWSER INSTANCES (RESTRICTED ACCESS VIA VPC ENDPOINT)

module "s3_bucket_secure_browser" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "laa-secure-browser-data-${random_string.secure_browser_bucket_suffix[0].result}"
  force_destroy = false

  # Versioning
  versioning = {
    enabled = true
  }

  # Server side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.secure_browser_bucket[0].arn
      }
      bucket_key_enabled = true
    }
  }

  # Public access block
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle configuration
  lifecycle_rule = [{
    id     = "secure_browser_data_lifecycle"
    status = "Enabled"

    expiration = {
      days = 270
    }

    noncurrent_version_expiration = {
      days = 30
    }
  }]

  # Bucket policy using the IAM policy document
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_bucket_secure_browser_policy[0].json

  tags = merge(
    local.tags,
    {
      Name = "laa-secure-browser-data"
    }
  )
}

resource "random_string" "secure_browser_bucket_suffix" {
  count = local.create_resources ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

# Bucket policy that restricts access to the VPC endpoint only
data "aws_iam_policy_document" "s3_bucket_secure_browser_policy" {
  count = local.create_resources ? 1 : 0

  # Deny data access that doesn't come from the VPC endpoint
  statement {
    sid    = "DenyDataAccessNotFromVPCEndpoint"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetObjectVersion",
      "s3:DeleteObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::laa-secure-browser-data-${random_string.secure_browser_bucket_suffix[0].result}",
      "arn:aws:s3:::laa-secure-browser-data-${random_string.secure_browser_bucket_suffix[0].result}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [module.vpc_endpoint_s3_interface[0].endpoints["s3_interface"].id]
    }
  }

  # Allow WorkSpaces Web service to access the bucket via the VPC endpoint
  statement {
    sid    = "AllowWorkSpacesWebAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["workspaces-web.amazonaws.com"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::laa-secure-browser-data-${random_string.secure_browser_bucket_suffix[0].result}",
      "arn:aws:s3:::laa-secure-browser-data-${random_string.secure_browser_bucket_suffix[0].result}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [module.vpc_endpoint_s3_interface[0].endpoints["s3_interface"].id]
    }
  }
}

### S3 INTERFACE ENDPOINT FOR SECURE BROWSER SUBNET ACCESS

module "s3_interface_endpoint_security_group" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "s3-interface-endpoint-secure-browser"
  description = "Security group for S3 interface endpoint - secure browser access only"
  vpc_id      = local.vpc_id

  # Allow HTTPS access from the secure browser subnet(s)
  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from secure browser subnets"
      cidr_blocks = join(",", [for subnet_id in local.subnet_ids : data.aws_subnet.secure_browser_subnets[subnet_id].cidr_block])
    }
  ]

  tags = merge(
    local.tags,
    {
      Name = "s3-interface-endpoint-secure-browser"
    }
  )
}

module "vpc_endpoint_s3_interface" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.21.0"

  vpc_id             = local.vpc_id
  subnet_ids         = local.subnet_ids
  security_group_ids = [module.s3_interface_endpoint_security_group[0].security_group_id]

  endpoints = {
    s3_interface = {
      service             = "s3"
      service_type        = "Interface"
      private_dns_enabled = false
      tags = merge(
        local.tags,
        {
          Name = "laa-secure-browser-s3-interface"
        }
      )
    }
  }

  tags = local.tags
}
