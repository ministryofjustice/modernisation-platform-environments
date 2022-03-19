variable "default_security_group" {
  description = "Should be true to adopt and manage default security group"
  type        = bool
  default     = true
}

variable "default_security_group_description" {
  description = "Description of Security Group"
  type        = string
  default     = "Managed by Terraform"

}

variable "default_security_group_tags" {
  description = "Additional tags for the default security group"
  type        = map(string)
  default     = {}
}

variable "default_security_group_name" {
  description = "Name to be used on the default security group"
  type        = string
  default     = null
}

variable "default_security_group_ingress" {
  description = "List of maps of ingress rules to set on the default security group"
  type        = list(map(string))
  default = [
    {
      cidr_blocks = "10.0.0.0/16"
      description = "Allow all from the local network."
      from_port   = 0
      protocol    = "-1"
      self        = false
      to_port     = 0
    },
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all HTTPS from the internet."
      from_port   = 443
      protocol    = "6"
      self        = false
      to_port     = 443
    },
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all HTTP from the internet."
      from_port   = 80
      protocol    = "6"
      self        = false
      to_port     = 80
    }
  ]
}

variable "default_security_group_egress" {
  description = "List of maps of egress rules to set on the default security group"
  type        = list(map(string))
  default = [
    {
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all"
      from_port   = 0
      protocol    = "-1"
      self        = false
      to_port     = 0
    }
  ]
}
