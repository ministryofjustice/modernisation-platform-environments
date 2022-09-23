variable "name" {
  description = "A name to identify the Glue Registry. This is unique to the AWS account and region the Stream is created in."
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(any)
}

variable "description" {
  description = "Resource Description"
  default     = "Glue Registry Resource"
}

variable "enable_glue_registry" {
  type        = bool
  default     = false
  description = "Whether to create Glue Registry"
}