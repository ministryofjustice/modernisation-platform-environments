variable "name" {
  description = "The EC2 Sec name."
}

variable "env" {
  type        = string
  default     = ""
  description = "Current Environment"
}

variable "app_key" {
  type        = string
  default     = ""
  description = "Current Environment"
}

variable "policies" {
  description = "Additional IAM policies to Attach to the Instance Role"
  type        = list(any)
  default     = []
}

variable "aws_region" {
  type        = string
  default     = ""
  description = "AWS Region"
}

variable "ec2_terminate_behavior" {}

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
  default = {
    "TCP_80" = {
      "from_port" = 80,
      "to_port" : 80,
      "protocol" = "TCP"
    },
    "TCP_443" = {
      "from_port" = 443,
      "to_port"   = 443,
      "protocol"  = "TCP"
    },
    "TCP_22" = {
      "from_port" = 22,
      "to_port"   = 22,
      "protocol"  = "TCP"
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

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = false
}

variable "enable_compute_node" {
  description = "Whether to Enable Compute Node, Setup EC2?"
  type        = bool
  default     = false
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

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile"
  type        = string
  default     = null
}

variable "ebs_size" {
  description = "EBS Block Size"
  default     = 20
}

variable "ebs_encrypted" {
  description = "If EBS to be Encrypted"
  type        = bool
  default     = true
}

variable "ebs_delete_on_termination" {
  description = "If true, the launched EBS Block to be Terminated with EC2"
  type        = bool
  default     = true
}

variable "region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account" {
  description = "AWS Account ID."
  default     = ""
}

variable "scale_down" {
  description = "Whether to scale down the auto scaling groups in the evening to save costs"
  type        = bool
  default     = true
}

#variable "s3_policy_arn" {
#  description = "S3 policy ARN, to be attached to Ec2 Instance Profile"
#}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource env vars."
}