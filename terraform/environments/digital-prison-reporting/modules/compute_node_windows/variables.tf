variable "name" {}
variable "app_key" {}
variable "ami_image_id" {}
variable "ec2_instance_type" {}
variable "subnet_ids" {}
variable "vpc" {}
variable "cidr" {
  type = list(string)
}
variable "aws_region" {}
variable "description" {
  default = "Security group for Windows compute node"
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
  default = 50
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
  default = "default-windows-key"
}
