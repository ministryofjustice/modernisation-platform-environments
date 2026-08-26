variable "monitor_name" {
  type = string
}

variable "aggregation_period" {
  type    = number
  default = 30
}

variable "destination" {
  type = string
}

variable "destination_port" {
  type = number
}

variable "protocol" {
  type    = string
  default = "TCP"
}

variable "packet_size" {
  type    = number
  default = 56
}

variable "source_arns" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}
