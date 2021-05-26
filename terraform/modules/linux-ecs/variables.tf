variable "region" {
}

variable "user_data"{
}

variable "account_name" {
  description = "The AWS account to deploy the code to"
}

variable "container_version" {
}

variable "app_count" {
  description = "Number of docker containers to run"
}

variable "app_name" {
}

variable "ami_image_id" {
  description = "EC2 AMI image to run in the ECS cluster"
}

variable "instance_type" {
  description = "EC2 instance type to run in the ECS cluster"
}

variable "key_name" {
  description = "Key to access EC2s in ECS cluster"
}

variable "container_cpu" {
  description = "Container instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "512"
}

variable "container_memory" {
  description = "Container instance memory to provision (in MiB)"
  default     = "1536"
}

variable "endpoint" {
}

variable "server_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 7001
}

variable "zone_id" {
  default = "true"
}

variable "cidr_access" {
  description = "List of the Cidr block for workspace access"
  type        = list(string)
}

variable "ec2_desired_capacity" {
  description = "Number of EC2s in the cluster"
}

variable "ec2_max_size" {
  description = "Max Number of EC2s in the cluster"
}

variable "ec2_min_size" {
  description = "Min Number of EC2s in the cluster"
}

variable "app_image" {
  default = ".dkr.ecr.eu-west-2.amazonaws.com/ccms-opa18-hub"
}

variable "health_check_path" {
  default = "/opa/opa-hub/manager"
}
variable "tags_common" {
  description = "MOJ required tags"
  type        = map(string)
}

variable "networking" {

  type = list(any)

  default = [{
    business-unit = "garden"
    set           = "general"
    application   = "core-sandbox"
  }]
}
variable "environment" {

}
