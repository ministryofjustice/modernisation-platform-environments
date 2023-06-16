variable "name" {
  type = string
}

# Account level info
variable "account" {
  type = map(any)
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
