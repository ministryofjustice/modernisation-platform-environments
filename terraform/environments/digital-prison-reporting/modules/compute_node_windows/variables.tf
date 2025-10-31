variable "name" {
  type = string
}
variable "app_key" {
  type = string
}
variable "ami_image_id" {
  type = string
}
variable "ec2_instance_type" {
  type = string
}
variable "subnet_ids" {
  type = string
}
variable "vpc" {
  type = string
}
variable "cidr" {
  type = list(string)
}
variable "aws_region" {
  type = string
}
variable "description" {
  type    = string
  default = "Security group for Windows compute node"
}
variable "ec2_terminate_behavior" {
  type = string
}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}
variable "enable_compute_node" {
  type    = bool
  default = false
}
variable "ebs_size" {
  type    = number
  default = 50
}
variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = null
}
variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}
variable "ebs_encrypted" {
  type    = bool
  default = true
}
variable "ebs_delete_on_termination" {
  description = "If true, the launched EBS Block to be Terminated with EC2"
  type        = bool
  default     = true
}
variable "ec2_sec_rules" {
  type = any
  default = {
    "TCP_3389" = {
      from_port = 3389,
      to_port   = 3389,
      protocol  = "TCP"
    }
  }
}
variable "policies" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "key_name" {
  type    = string
  default = ""
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource env vars."
}