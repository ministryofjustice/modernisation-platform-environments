variable "call_centre_staging_aws_s3_bucket" {
  type        = string
  description = "AWS S3 call centre staging bucket name"
  default     = "call-centre-staging"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
}

variable "json_encode_decode_version" {
  type        = string
  description = ""
  default     = "2012-10-17"
}

variable "aws_guardduty_detector_enable" {
  type        = bool
  description = ""
  default     = true
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
  default     = "arn:aws:iam::803963757240:root"
}

variable "bt_genesys_aws_s3_bucket_policy_statement_action" {
  type        = list(any)
  description = ""
  default = [
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:ListBucket"
  ]
}

variable "bt_genesys_aws_s3_bucket_policy_statement_resource" {
  type        = list(any)
  description = ""
  default = [
    "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
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
