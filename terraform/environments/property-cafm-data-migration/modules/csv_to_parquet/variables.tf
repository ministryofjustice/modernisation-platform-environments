variable "name" { 
    type = string 
}

variable "source_bucket_name" { 
    type = string 
}
variable "source_bucket_arn" { 
    type = string 
}

variable "dest_bucket_name" {
  type = string
}

variable "dest_bucket_arn" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}