variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}


variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "environment" {
  description = "The environment for the ECS cluster"
  type        = string
}

variable "ecs_service_internal_sg_id" {
  description = "The security group ID for internal ECS services"
  type        = string
}

variable "ecs_service_external_sg_id" {
  description = "The security group ID for external ECS services"
  type        = string
}

variable "esb_service_sg_id" {
  description = "Security Group ID for ESB"
  type        = string
}

variable "rds_cluster_security_group_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "private_ip" {
  description = "Private IP for the instance"
  type        = string
}

variable "ami" {
  description = "AMI for the instance"
  type        = string
}

variable "tableau_sg_id" {
  description = "Security group ID for Tableau"
  type        = string
}

variable "secret_kms_key_arn" {
  description = "The ARN of the KMS key to use for secrets"
  type        = string
}

variable "private_subnet_list" {
  type = list(object({
    id                = string
    availability_zone = string
    cidr_block        = string
  }))
}

variable "management_server_sg_id" {
  description = "The ID of the management server security group"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "yjsm_role_additional_policies_arns" {
  description = "List of additional policy ARNs to attach to the YJSM role"
  type        = list(string)
  default     = []
}

variable "yjsm_secrets_access_policy_secret_arns" {
  description = "A list of secret ARNs to allow access to"
  type        = string
}
