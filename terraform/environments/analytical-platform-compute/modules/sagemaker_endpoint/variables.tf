variable "name" {
  description = "Name for the SageMaker endpoint"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the SageMaker model"
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository containing the model image"
  type        = string
}

variable "image_tag" {
  description = "Image tag for the ECR model image"
  type        = string
}

variable "environment" {
  description = "Environment variables for the SageMaker container"
  type        = map(string)
}

variable "s3_model_key" {
  description = "S3 key for the model data"
  type        = string
  default     = null
}

variable "s3_model_bucket_name" {
  description = "S3 bucket name for model data"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}
