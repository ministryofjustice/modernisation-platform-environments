variable "env_name" {
  description = "The name of the env where file system is being created"
  type        = string
}

variable "tags" {
  description = "tags to add for all resources"
  type        = map(string)
  default = {
  }
}


