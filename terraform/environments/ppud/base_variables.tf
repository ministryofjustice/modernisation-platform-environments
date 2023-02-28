variable "networking" {
  type = list(any)
}

variable "instance_ids_wam_alb" {
  type = map(list(string))
  default = {
    "development" = [data.aws_instance.s609693lo6vw105.id]
    "preprod" = [data.aws_instance.s618358rgvw201.id]
    #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}

variable "instance_ids_ppud_internal_alb" {
  type = map(list(string))
  default = {
     "preprod" = [data.aws_instance.s618358rgvw023.id]
  #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}