variable "account_id" {
  description = "The account id"
}

variable "local_tags" {
  description = "The predefined local.tags"
}

variable "source_bucket" {
  description = "The bucket to have server access logging"
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
  default     = {}
}
