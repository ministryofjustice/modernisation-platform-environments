variable "networking" {
  type = list(any)
}

/*
variable "instance_ids_wam_alb" {
  type = map(list(string))
  default = {
     development = ["i-0250650f9a020e097"]
     preprod = ["i-0250650f9a020e097"]
    #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}

variable "instance_ids_ppud_internal_alb" {
  type = map(list(string))
  default = {
     preprod = ["i-0250650f9a020e097"]
  #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}
*/