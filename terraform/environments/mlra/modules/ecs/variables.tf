variable "app_count" {
  type        = string
  description = "Number of docker containers to run"
}

variable "app_name" {
  type        = string
  description = "Name of the application"
}


variable "container_instance_type" {
  type        = string
  description = "Container OS being used (windows or linux)"
  validation {
    condition     = contains(["windows", "linux"], var.container_instance_type)
    error_message = "Valid values for var: container_instance_type are (windows, linux)."
  }
}


variable "ec2_desired_capacity" {
  type        = string
  description = "Number of EC2s in the cluster"
}

variable "ec2_max_size" {
  type        = string
  description = "Max Number of EC2s in the cluster"
}

variable "ec2_min_size" {
  type        = string
  description = "Min Number of EC2s in the cluster"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type to run in the ECS cluster"
}

variable "key_name" {
  type        = string
  description = "Key to access EC2s in ECS cluster"
}

variable "lb_tg_arn" {
  type        = string
  description = "Load balancer target group ARN used by ECS service"
}

variable "network_mode" {
  type        = string
  description = "The network mode used for the containers in the task. If OS used is Windows network_mode must equal none."
  validation {
    condition     = contains(["none", "bridge", "host", "awsvpc"], var.network_mode)
    error_message = "Valid values for var: network_mode are (none, bridge, host, awsvpc)."
  }
}

variable "server_port" {
  type        = string
  description = "The port the containers will be listening on"
}

variable "subnet_set_name" {
  type        = string
  description = "The name of the subnet set associated with the account"
}

variable "tags_common" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "ec2_ingress_rules" {
  description = "Security group ingress rules for the cluster EC2s"
  type = map(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = list(string)
    cidr_blocks     = list(string)
  }))
}

variable "ec2_egress_rules" {
  description = "Security group egress rules for the cluster EC2s"
  type = map(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    security_groups = list(string)
    cidr_blocks     = list(string)
  }))
}

variable "task_definition" {
  type        = string
  description = "Task definition to be used by the ECS service"
}

variable "task_definition_volume" {
  type        = string
  description = "Name of the volume referenced in the sourceVolume parameter of container definition in the mountPoints section"
}

variable "appscaling_min_capacity" {
  type        = number
  description = "Minimum capacity of the application scaling target"
  default     = 2
}

variable "appscaling_max_capacity" {
  type        = number
  description = "Maximum capacity of the application scaling target"
  default     = 6
}

variable "user_data" {
  type        = string
  description = "The configuration used when creating EC2s used for the ECS cluster"
}

variable "vpc_all" {
  type        = string
  description = "The full name of the VPC (including environment) used to create resources"
}

variable "ec2_scaling_cpu_threshold" {
  type        = string
  description = "The cpu threshold for ec2 cluster scaling"
}

variable "ec2_scaling_mem_threshold" {
  type        = string
  description = "The utilised memory threshold for ec2 cluster scaling"
}

variable "ecs_scaling_cpu_threshold" {
  type        = string
  description = "The cpu threshold for ecs cluster scaling"
}

variable "ecs_scaling_mem_threshold" {
  type        = string
  description = "The utilised memory threshold for ec2 cluster scaling"
}

variable "region" {
  type        = string
  description = "Region in AWS"
}

variable "account_number" {
  type        = string
  description = "Account number of current environment"
}

variable "maatdb_password_secret_name" {
  type        = string
  description = "Parameter store secret name containing the MAATDB database password"
}

variable "app_master_password_name" {
  type        = string
  description = "Parameter store secret name containing the master password"
}

variable "app_salt_name" {
  type        = string
  description = "Parameter store secret name containing the salt"
}

variable "app_derivation_iterations_name" {
  type        = string
  description = "Parameter store secret name containing the derivation iterations"
}

variable "gtm_id_secret_name" {
  type        = string
  description = "Parameter store secret name containing the Google Tag Manager Id"
}

variable "infox_client_secret" {
  type        = string
  description = "Parameter store secret name containing the InfoX client secret"
}

variable "ecs_target_capacity" {
  type        = string
  description = "The target value for the CloudWatch metric used in the Amazon ECS-managed target tracking scaling policy. For example, a value of 100 will result in the Amazon EC2 instances in your Auto Scaling group being completely utilized."
}

variable "environment" {
  type        = string
  description = "Environment of the application"
}

variable "maatdb_rds_sec_group_id" {
  type        = string
  description = "MAATDB sec group ID"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB Security Group ID"
}

variable "maat_api_client_id_name" {
  type        = string
  description = "Parameter store secret name containing the MAAT API Client ID"
}

variable "maat_api_client_secret_name" {
  type        = string
  description = "Parameter store secret name containing the MAAT API Client Secret"
}