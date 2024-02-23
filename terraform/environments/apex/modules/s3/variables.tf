variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
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

