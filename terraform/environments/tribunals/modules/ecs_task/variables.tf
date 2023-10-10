variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "task_definition_volume" {
  type        = string
  description = "Name of the volume referenced in the sourceVolume parameter of container definition in the mountPoints section"
}

variable "task_definition" {
  type        = string
  description = "Task definition to be used by the ECS service"
}

variable "tags_common" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}


