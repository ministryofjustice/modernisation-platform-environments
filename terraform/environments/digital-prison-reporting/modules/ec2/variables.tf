variable "name" {
  description = "The EC2 Sec name."
}

variable "description" {
  type        = string
  default     = ""
  description = "(Optional) Description"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "vpc" {}

variable "ec2_sec_rules" {
  description = "A Map of map of security group Rules to associate with"
  default     = {
                "TCP_80": {
                    "from_port": 80,
                    "to_port": 80,
                    "protocol": "TCP"
                },
                "TCP_443": {
                    "from_port": 443,
                    "to_port": 443,
                    "protocol": "TCP"
                }
            }
}

variable "cidr" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "ec2_instance_type" {}
variable "ami_image_id" {}

variable "subnet_ids" {
  description = "subnet IDs to associate with"
  default     = null
}