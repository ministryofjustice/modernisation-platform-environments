variable "name" {
  type = string
}

# Account level info
variable "account_info" {
  type = object({
    business_unit  = string,
    region         = string,
    vpc_id         = string,
    mp_environment = string
  })
}

variable "ldap_config" {
  type = object({
    name                 = string
    some_other_attribute = optional(string)
  })
  default = {
    name                 = "default_name"
    some_other_attribute = "default_some_other_attribute"
  }

}

variable "db_config" {
  type = object({
    name                 = string
    some_other_attribute = optional(string)
  })
  default = {
    name                 = "default_name"
    some_other_attribute = "default_some_other_attribute"
  }
}
