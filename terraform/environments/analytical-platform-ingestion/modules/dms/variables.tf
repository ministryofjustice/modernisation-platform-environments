variable "environment" {
  type        = string
  description = "The environment name"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID"
}

variable "db" {
  type        = string
  description = "The database name"
}

variable "dms_replication_instance" {
  type = object({
    replication_instance_id      = string
    subnet_group_id              = optional(string)
    subnet_group_name            = optional(string)
    subnet_cidrs                 = optional(list(string))
    allocated_storage            = number
    availability_zone            = string
    engine_version               = string
    kms_key_arn                  = optional(string)
    multi_az                     = bool
    replication_instance_class   = string
    inbound_cidr                 = string
    apply_immediately            = optional(bool, false)
    preferred_maintenance_window = optional(string, "sun:10:30-sun:14:30")
  })

  validation {
    condition     = contains(["3.5.2", "3.5.3", "3.5.4"], var.dms_replication_instance.engine_version)
    error_message = "Valid values for var: test_variable are ('3.5.2', '3.5.3', '3.5.4')."
  }
}

variable "replication_task_id" {
  type = object({
    full_load = string
    cdc       = optional(string)
  })
}

variable "dms_source" {
  type = object({
    protocol                    = string,
    engine_name                 = string,
    secrets_manager_arn         = string,
    secrets_manager_kms_arn     = string,
    sid                         = string,
    extra_connection_attributes = optional(string, "")
    cdc_start_time              = optional(string)
  })

  validation {
    condition     = contains(["oracle", "sqlserver"], var.dms_source.engine_name)
    error_message = "Valid values for var: test_variable are ('oracle', 'sqlserver')."
  }

  description = <<EOF
    extra_connection_attributes: Extra connection attributes to be used in the connection string</br>
    cdc_start_time: The start time for the CDC task, this will need to be set to a date after the database setup has been complete (this is to ensure the logs are available)
  EOF
}

variable "dms_target_prefix" {
  type        = string
  default     = ""
  description = "The prefix for the s3 target endpoint (optional)"
}

variable "dms_mapping_rules" {
  type        = string
  description = "The path to the mapping rules file"
}

variable "output_bucket" {
  type        = string
  default     = ""
  description = <<EOF
    The name of the output bucket (optional, bucket will be generated if not specified)
    Note that if this is specified, it is assumed all related aws_s3_bucket_* resources are being managed externally and so will not be generated within this module
  EOF
}

variable "s3_target_config" {
  type = object({
    add_column_name       = bool
    max_batch_interval    = number
    min_file_size         = number
    timestamp_column_name = string
  })
  default = {
    add_column_name       = true
    max_batch_interval    = 3600
    min_file_size         = 32000
    timestamp_column_name = "EXTRACTION_TIMESTAMP"
  }
}

variable "tags" {
  type = map(string)
}

variable "create_premigration_assessement_resources" {
  type        = bool
  default     = false
  description = "whether to create pre-requisites for DMS PreMigration Assessment to be run manually"
}

variable "retry_failed_after_recreate_metadata" {
  type        = bool
  default     = true
  description = "Whether to retry validation of failures after regenerating metadata"
}

variable "write_metadata_to_glue_catalog" {
  type        = bool
  default     = true
  description = "Whether to write metadata to glue catalog"
}

variable "valid_files_mutable" {
  type        = bool
  default     = false
  description = "If false, copy valid files to their destination bucket with a datetime infix"
}

variable "create_ancillary_static_roles" {
  type        = bool
  default     = true
  description = <<EOF
    AWS DMS requires roles of a specific name to be created for vpc/cloudwatch, which can cause
    issues if two or more invocations of this module live in the same environment.
    If false, assume these roles have been created by another invocation
  EOF
}


variable "glue_catalog_account_id" {
  type        = string
  default     = ""
  description = "Which glue catalog to grant metadata generator permissions to (optional)"
}

variable "glue_catalog_role_arn" {
  type        = string
  default     = ""
  description = "Which role to use to access glue catalog (optional)"
}

variable "glue_catalog_database_name" {
  type        = string
  default     = ""
  description = "Which database to write to in glue catalog (optional)"
}

variable "glue_destination_bucket" {
  type        = string
  default     = ""
  description = <<EOF
    The name of the bucket pointed to in the glue metadata (optional)
    This is useful if this parameter must be different to the output bucket, e.g. because of bucket replication
  EOF
}

variable "metadata_generator_allowed_triggers" {
  type        = map(any)
  default     = {}
  description = "Which services can invoke metadata generator lambda (see https://github.com/terraform-aws-modules/terraform-aws-lambda?tab=readme-ov-file#lambda-permissions-for-allowed-triggers)"
}
