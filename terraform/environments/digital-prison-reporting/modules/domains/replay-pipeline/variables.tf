variable "setup_replay_pipeline" {
  description = "Enable Replay Pipeline, True or False?"
  type        = bool
  default     = false
}

variable "replay_pipeline" {
  description = "Name for the Replay Pipeline"
  type        = string
  default     = ""
}

variable "pipeline_additional_policies" {
  description = "Pipeline Additional policies"
  type        = list(string)
  default     = []
}

variable "glue_stop_glue_instance_job" {
  description = "Name of job to stop the current running instance of the streaming job"
  type        = string
  default     = ""
}

variable "glue_s3_file_transfer_job" {
  description = "Name of s3 file transfer job"
  type        = string
  default     = ""
}

variable "glue_switch_prisons_hive_data_location_job" {
  description = "Name of glue job to switch the prisons hive data location"
  type        = string
  default     = ""
}

variable "glue_s3_data_deletion_job" {
  description = "Name of glue job which deletes parquet files from s3 bucket(s)"
  type        = string
  default     = ""
}

variable "glue_reporting_hub_batch_jobname" {
  description = "Glue Reporting Hub Batch JobName"
  type        = string
  default     = ""
}

variable "glue_reporting_hub_cdc_jobname" {
  description = "Glue Reporting Hub CDC JobName"
  type        = string
  default     = ""
}

variable "s3_glue_bucket_id" {
  description = "S3, Glue Bucket ID"
  type        = string
  default     = ""
}

variable "s3_raw_bucket_id" {
  description = "S3, RAW Bucket ID"
  type        = string
  default     = ""
}

variable "s3_raw_archive_bucket_id" {
  description = "S3, RAW Archive Bucket ID"
  type        = string
  default     = ""
}

variable "s3_structured_bucket_id" {
  description = "S3, Structured Bucket ID"
  type        = string
  default     = ""
}

variable "s3_curated_bucket_id" {
  description = "S3, Curated Bucket ID"
  type        = string
  default     = ""
}

variable "s3_temp_reload_bucket_id" {
  description = "S3 Bucket ID for the temporary location to store reload data"
  type        = string
  default     = ""
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "domain" {
  type        = string
  default     = ""
  description = "Domain Name"
}