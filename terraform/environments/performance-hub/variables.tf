variable "region" {
  type        = string
  description = ""
  default     = "eu-west-2"
}

variable "container_version" {

}

variable "db_password_key" {

}

variable "app_count" {
  description = "Number of docker containers to run"
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
  default     = "512"
}

variable "server_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 7001
}

# variable "cidr_access" {
#   description = "List of the Cidr block for workspace access"
#   type        = list(string)
# }

variable "ec2_desired_capacity" {
  description = "Number of EC2s in the cluster"
}

variable "ec2_max_size" {
  description = "Max Number of EC2s in the cluster"
}

variable "ec2_min_size" {
  description = "Min Number of EC2s in the cluster"
}

variable "db_user" {

}

variable "ecr_url" {
  default = ""
}


variable "db_snapshot_identifier" {
  description = "The default database snapshot to restore from"
  default     = "performance-hub-initial"
}
#
# variable "health_check_path" {
#   default = "/opa/opa-hub/manager"
# }
