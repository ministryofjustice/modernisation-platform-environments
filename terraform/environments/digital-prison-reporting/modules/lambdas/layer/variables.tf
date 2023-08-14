# Lambda Layers
variable "layer_name" {
  description = "Name of Lambda Layer to create"
  type        = string
  default     = ""
}

variable "local_file" {
  description = "The path to the local Layer binary File."
  default     = null
  type        = string
}

variable "layer_skip_destroy" {
  description = "Whether to retain the old version of a previously deployed Lambda Layer."
  type        = bool
  default     = false
}

variable "license_info" {
  description = "License info for your Lambda Layer. Eg, MIT or full url of a license."
  type        = string
  default     = ""
}

variable "description" {
  description = "Description for your Lambda Layer"
  type        = string
  default     = ""
}

variable "compatible_runtimes" {
  description = "A list of Runtimes this layer is compatible with. Up to 5 runtimes can be specified."
  type        = list(string)
  default     = []
}

variable "compatible_architectures" {
  description = "A list of Architectures Lambda layer is compatible with. Currently x86_64 and arm64 can be specified."
  type        = list(string)
  default     = null
}

variable "s3_existing_package" {
  description = "The S3 bucket object with keys bucket, key, version pointing to an existing zip-file to use"
  type        = map(string)
  default     = null
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function."
  type        = list(string)
  default     = null
}

variable "create_layer" {
  type        = bool
  default     = false
  description = "(Optional) Create Lambda Layer, Yes Or NO"
}