variable "dataset_name" {
  type    = string
  nullable = false
}

variable "iam_role" {
  type = object({
    name = string
    arn  = string
    id   = string
  })
  nullable = false
}

variable "memory_size" {
    type = number
    nullable = false
    default = 240
}
variable "timeout" {
    type = number
    nullable = false
    default = 60
}
variable "function_tag" {
    type = string
    nullable = false
    default = "v0.0.0-884806f"
}
