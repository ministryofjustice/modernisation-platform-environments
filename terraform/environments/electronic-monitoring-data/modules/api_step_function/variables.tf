# API Gateway Variables
variable "api_name" {
  description = "The name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "The description of the API Gateway"
  type        = string
}

variable "api_path" {
  description = "The path for the resource under API Gateway"
  type        = string
}

variable "http_method" {
  description = "HTTP method to be used (GET, POST, etc.)"
  type        = string
  default     = "POST"
}

variable "authorization" {
  description = "The authorization method for the API Gateway method"
  type        = string
  default     = "NONE"
}

variable "step_function" {
  description = "ARN of the Step Function to trigger"
  type        = object({ id = string, arn = string })
}

variable "stages" {
  description = "Stage settings"
  type = list(
    object(
      {
        stage_name             = string,
        stage_description      = string,
        burst_limit            = number,
        rate_limit             = number,
        throttling_burst_limit = number,
        throttling_rate_limit  = number
      }
    )
  )
}

variable "schema" {
  description = "The expected schema of the API"
  type        = any
}

variable "sync" {
  description = "Boolean value of whether API should return output of step function"
  type        = bool
  default     = true
}


variable "api_version" {
  description = "The version of the API Gateway"
  type        = string
}
