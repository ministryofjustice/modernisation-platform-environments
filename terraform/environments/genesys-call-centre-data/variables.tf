variable "call_centre_staging_aws_s3_bucket" {
    type        = string
    description = "AWS S3 call centre staging bucket name"
    default     = "call-centre-staging"
}

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

variable "aws_s3_bucket_tags_environment" {
    type        = string
    description = ""
    default     = "production"
}

variable "aws_s3_bucket_policy" {
    type        = string
    description = ""
    default     = ""
}

variable "aws_s3_bucket_policy_depends_on" {
    type        = string
    description = ""
    default     = ""
}

variable "aws_guardduty_detector_enable" {
    type        = bool
    description = ""
    default     = true
}

variable "aws_guardduty_publishing_destination_detector_id" {
    type        = string
    description = ""
    default     = ""
}

variable "aws_guardduty_publishing_destination_destination_arn" {
    type        = string
    description = ""
    default     = ""
}

variable "aws_guardduty_publishing_destination_kms_key_arn" {
    type        = string
    description = ""
    default     = ""
}

variable "aws_kms_key_description" {
    type        = string
    description = ""
    default     = ""
}

variable "aws_kms_key_usage" {
    type        = string
    description = ""
    default     = ""
}

variable "bt_genesys_aws_third_party_account_id" {
    type        = string
    description = "The AWS account ID of the BT Genesys third-party organisation."
    default     = "1234"
}
