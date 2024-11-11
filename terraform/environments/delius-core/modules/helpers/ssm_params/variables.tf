variable "environment_name" {
  type = string

}

variable "application_name" {
  type = string

}

variable "params_plain" {
  type    = list(string)
  default = []
}

variable "params_secure" {
  type    = list(string)
  default = []
}
