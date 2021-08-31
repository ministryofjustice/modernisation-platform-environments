variable "app_name" {
  type = string
}

variable "source_image_name" {
  type = string
}

variable "source_image_owner_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "skip_create_ami" {
  type    = bool
  default = false
}