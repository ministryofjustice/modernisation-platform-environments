variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "bucket_name" {
  type        = list(string)
  description = "Names of s3 buckets that are not to be replicated from the old environments."
  default     = []
  validation {
    condition = alltrue([
      for o in var.bucket_name : length(o) < 37
    ])
    error_message = "Maximum length of bucket names is 36 characters."
  }
}

variable "transfer_bucket_name" {
  type        = list(string)
  description = "Names of S3 buckets that are to be transferred as is from the old environments."
  default     = []
  validation {
    condition = alltrue([
      for o in var.transfer_bucket_name : length(o) < 37
    ])
    error_message = "Maximum length of bucket names is 36 characters."
  }

}

variable "archive_bucket_name" {
  type        = list(string)
  description = "Names of S3 buckets that are to repliccated to an archive bucket."
  default     = []
  validation {
    condition = alltrue([
      for o in var.archive_bucket_name : length(o) < 37
    ])
    error_message = "Maximum length of bucket names is 36 characters."
  }
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
  default     = {}
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

variable "log_bucket" {
  type        = string
  description = "Bucket to send logs to. It will be created by this module."
  default     = null
}

variable "add_log_policy" {
  type        = bool
  description = "Se to tur to show that a bucket is being created to receive s3 access logs."
  default     = false
}

variable "allow_replication" {
  type        = bool
  description = "Used to indicate that policy should be assigned to enable replication from the equivelent old account."
  default     = false
}

variable "s3_source_account" {
  type        = string
  description = "Source account from whch s3 buckets may be replicated."
  default     = null
}

variable "cors_policy_map" {
  description = "Map of bucket name => CORS policy"
  type        = map(any)
  default     = {}
}