# STEP FUNCTION, Pipeline
variable "setup_data_ingestion_pipeline"  {
  description = "Enable Data Ingestion Pipeline, True or False ?"
  type        = bool
  default     = false
}

variable "data_ingestion_pipeline"  {
  description = "Name for Data Ingestion Pipeline"
  type        = string
  default     = ""  
}

variable "pipeline_dms_task_time_out"  {
  description = "DMS Task Timeout"
  type        = number
  default     = 300
}

variable "pipeline_additional_policies" {
  description = "Pipeline Additional policies"
  type        = list(string)
  default     = []
}

variable "dms_replication_task_arn" {}

variable "pipeline_notification_lambda_function" {
  description = "Pipeline Notification Lambda Name"
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

variable "s3_file_transfer_lambda_function" {
  description = "S3 File Transfer Lambda Function Name"
  type        = string
  default     = "" 
}

variable "glue_hive_table_creation_jobname" {
  description = "Glue Hive Table Creation JobName"
  type        = string
  default     = "" 
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}