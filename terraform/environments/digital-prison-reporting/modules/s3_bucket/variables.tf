
variable "name" {
  description = "Name of the Bucket"
  default     = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(any)
}