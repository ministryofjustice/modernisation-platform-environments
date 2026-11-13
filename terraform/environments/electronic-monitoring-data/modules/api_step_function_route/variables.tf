variable "route_name" {
  description = "Unique name for the API Gateway route resources"
  type        = string
}

variable "rest_api_id" {
  description = "ID of the API Gateway REST API"
  type        = string
}

variable "parent_resource_id" {
  description = "ID of the parent API Gateway resource"
  type        = string
}

variable "api_path" {
  description = "Path for the resource under API Gateway"
  type        = string
}

variable "http_method" {
  description = "HTTP method to be used"
  type        = string
  default     = "POST"
}

variable "step_function" {
  description = "Step Function triggered by the route"
  type        = object({ id = string, arn = string })
}

variable "schema" {
  description = "Expected request schema"
  type        = any
}

variable "sfn_type" {
  description = "Step Function type: standard or express"
  type        = string
  default     = "standard"
}

variable "enable_status_check" {
  description = "Enable the GET /status/{execution_id} endpoint"
  type        = bool
  default     = false
}
