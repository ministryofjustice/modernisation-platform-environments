variable "account_id" {
  type = string
}

variable "application_name" {
  type = string
}

variable "download_bucket_arn" {
  type = string
}

variable "download_bucket_kms_key_arn" {
  type = string
}

variable "download_bucket_name" {
  type = string
}

variable "idempotency_table_arn" {
  type = string
}

variable "idempotency_table_id" {
  type = string
}

variable "max_presigned_url_expiry_seconds" {
  type = number
}

variable "name_suffix" {
  type = string
}

variable "presigned_url_expiry_seconds" {
  type = number
}

variable "slack_channel_id" {
  type = string
}

variable "slack_team_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
