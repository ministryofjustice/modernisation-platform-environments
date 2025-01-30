variable "call_centre_staging_aws_s3_bucket" {
  type        = string
  description = "AWS S3 call centre staging bucket name"
  default     = "call-centre-staging"
}

variable "json_encode_decode_version" {
  type        = string
  description = ""
  default     = "2012-10-17"
}

variable "notification_sns_arn" {
  type        = string
  description = "The arn for the bucket notification SNS topic"
  default     = ""
}

variable "notification_enabled" {
  type        = bool
  description = "Boolean indicating if a notification resource is required for the bucket"
  default     = false
}

variable "notification_events" {
  type        = list(string)
  description = "The event for which we send notifications"
  default     = [""]
}

variable "sse_algorithm" {
  type        = string
  description = "The server-side encryption algorithm to use"
  default     = "aws:kms"
}

variable "custom_kms_key" {
  type        = string
  description = "KMS key ARN to use"
  default     = ""
}

variable "versioning_enabled" {
  type        = bool
  description = "Activate S3 bucket versioning"
  default     = true
}

variable "lifecycle_rule" {
  description = "List of maps containing configuration of object lifecycle management."
  type        = any
  default = [{
    id      = "main"
    enabled = "Enabled"
    prefix  = ""
    tags = {
      rule      = "log"
      autoclean = "true"
    }
    transition = [
      {
        days          = 90
        storage_class = "STANDARD_IA"
        }, {
        days          = 365
        storage_class = "GLACIER"
      }
    ]
    expiration = {
      days = 730
    }
    noncurrent_version_transition = [
      {
        days          = 90
        storage_class = "STANDARD_IA"
        }, {
        days          = 365
        storage_class = "GLACIER"
      }
    ]
    noncurrent_version_expiration = {
      days = 730
    }
  }]
}

variable "log_buckets" {
  type        = map(any)
  description = "Map containing log bucket details and its associated bucket policy."
  default     = null
  nullable    = true
}

variable "log_bucket_name" {
  type        = string
  description = ""
  default     = ""
  nullable    = true
}

variable "log_partition_date_source" {
  type        = string
  default     = "None"
  description = "Partition logs by date. Allowed values are 'EventTime', 'DeliveryTime', or 'None'."

  validation {
    condition     = contains(["EventTime", "DeliveryTime", "None"], var.log_partition_date_source)
    error_message = "log_partition_date_source must be either 'EventTime', 'DeliveryTime', or 'None'."
  }
}

variable "replication_enabled" {
  type        = bool
  description = "Activate S3 bucket replication"
  default     = false
}

variable "replication_region" {
  type        = string
  description = "Region to create S3 replication bucket"
  default     = "eu-west-2"
}

variable "custom_replication_kms_key" {
  type        = string
  description = "KMS key ARN to use for replication to eu-west-2"
  default     = ""
}

variable "log_prefix" {
  type        = string
  description = "Prefix for all log object keys."
  default     = null
  nullable    = true
}

variable "aws_guardduty_detector_enable" {
  type        = bool
  description = ""
  default     = true
}

variable "aws_guardduty_organization_admin_account_id" {
  type        = string
  description = ""
  default     = "211125476974"
}

variable "aws_guardduty_member_email" {
  type        = string
  description = ""
  default     = "ebubechukwu.obara@justice.gov.uk"
}

variable "aws_guardduty_member_invite" {
  type        = bool
  description = ""
  default     = true
}

variable "aws_guardduty_member_disable_email_notification" {
  type        = bool
  description = ""
  default     = false
}

variable "moj_aws_s3_bucket_policy_statement_sid" {
  type        = string
  description = ""
  default     = "AllowAccountFullAccess"
}

variable "moj_aws_s3_bucket_policy_statement_effect" {
  type        = string
  description = ""
  default     = "Allow"
}

variable "moj_aws_s3_bucket_policy_statement_principal_service" {
  type        = string
  description = ""
  default     = "s3.amazonaws.com"
}

variable "moj_aws_s3_bucket_policy_statement_action" {
  type        = string
  description = ""
  default     = "s3:*"
}

variable "moj_aws_iam_policy_document_statement_effect" {
  type        = string
  description = ""
  default     = "Allow"
}

variable "moj_aws_iam_policy_document_statement_actions" {
  type        = list
  description = ""
  default     = [
    "sts:AssumeRole"
  ]
}

variable "moj_aws_iam_policy_document_principals_type" {
  type        = string
  description = ""
  default     = "Service"
}

variable "moj_aws_iam_policy_document_principals_identifiers" {
  type        = list
  description = ""
  default     = [
    "s3.amazonaws.com"
  ]
}

variable "moj_aws_s3_bucket_replication_configuration_rule_id" {
  type        = string
  description = ""
  default     = "SourceToDestinationReplication"
}

variable "moj_aws_s3_bucket_replication_configuration_rule_destination_storage_class" {
  type        = string
  description = ""
  default     = "STANDARD"
}

variable "suffix_name" {
  type        = string
  default     = ""
  description = "Suffix for role and policy names"
}

variable "bt_genesys_aws_s3_bucket_policy_statement_sid" {
  type        = string
  description = ""
  default     = "AllowThirdPartyWriteOnly"
}

variable "bt_genesys_aws_s3_bucket_policy_statement_effect" {
  type        = string
  description = ""
  default     = "Allow"
}

variable "bt_genesys_aws_s3_bucket_policy_statement_principal_aws" {
  type        = string
  description = "The AWS account ID of the BT Genesys third-party organisation."
  default     = "arn:aws:iam::684969100054:root"
}

variable "bt_genesys_aws_s3_bucket_policy_statement_action" {
  type        = list(any)
  description = ""
  default = [
    "s3:PutObject",
    "s3:ListBucket"
  ]
}

variable "aws_kms_key_s3_description" {
  type        = string
  description = ""
  default     = "KMS key for GuardDuty publishing"
}

variable "aws_kms_key_s3_key_usage" {
  type        = string
  description = ""
  default     = "ENCRYPT_DECRYPT"
}

variable "aws_kms_key_s3_policy_statement_sid" {
  type        = string
  description = ""
  default     = "AllowGuardDutyAccess"
}

variable "aws_kms_key_s3_policy_statement_effect" {
  type        = string
  description = ""
  default     = "Allow"
}

variable "aws_kms_key_s3_policy_statement_principal_service" {
  type        = string
  description = ""
  default     = "guardduty.amazonaws.com"
}

variable "aws_kms_key_s3_policy_statement_action" {
  type        = string
  description = ""
  default     = "kms:*"
}

variable "aws_kms_key_s3_policy_statement_resource" {
  type        = string
  description = ""
  default     = "*"
}

###

variable "call_centre_landing_aws_s3_bucket" {
  type        = string
  description = "AWS S3 call centre landing bucket name"
  default     = "call-centre-landing"
}

variable "call_centre_logs_aws_s3_bucket" {
  type        = string
  description = "AWS S3 call centre logs bucket name"
  default     = "call-centre-logs"
}

variable "call_centre_archive_aws_s3_bucket" {
  type        = string
  description = "AWS S3 call centre staging bucket name"
  default     = "call-centre-archive"
}

variable "call_centre_ingestion_aws_s3_bucket" {
  type        = string
  description = "AWS S3 call centre ingestion bucket name"
  default     = "call-centre-ingestion"
}

variable "call_centre_curated_aws_s3_bucket" {
  type        = string
  description = "AWS S3 call centre curated bucket name"
  default     = "call-centre-curated"
}

variable "ownership_controls" {
  type        = string
  description = "Bucket Ownership Controls - for use WITH acl var above options are 'BucketOwnerPreferred' or 'ObjectWriter'. To disable ACLs and use new AWS recommended controls set this to 'BucketOwnerEnforced' and which will disabled ACLs and ignore var.acl"
  default     = "ObjectWriter"
}

variable "acl" {
  type        = string
  description = "Use canned ACL on the bucket instead of BucketOwnerEnforced ownership controls. var.ownership_controls must be set to corresponding value below."
  default     = "private"
}

variable "replication_bucket" {
  type        = string
  description = "Name of bucket used for replication - if not specified then * will be used in the policy"
  default     = ""
}

variable "bucket_name" {
  type        = string
  description = "Please use bucket_prefix instead of bucket_name to ensure a globally unique name."
  default     = null
}

variable "bucket_prefix" {
  type        = string
  description = "Bucket prefix, which will include a randomised suffix to ensure globally unique names"
  default     = null
}

# variable "tags" {
#   type        = map(any)
#   description = "Tags to apply to resources, where applicable"
# }
