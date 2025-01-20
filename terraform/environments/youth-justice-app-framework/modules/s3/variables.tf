variable "bucket_name" {
  type        = list(string)
  description = "S3 bucket name"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment_name" {
  type        = string
  description = "Environment name"
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
  description = "Bucket to send logs to"
  default     = null
}

variable "allow_replication" {
  type        = bool
  description = "Used to indicate that policy should be assigned to enable replication from the equivelent old account."
  default     = true
}

variable "s3_source_account" {
  type        = string
  description = "Source account from whch s3 buckets may be replicated."
 }