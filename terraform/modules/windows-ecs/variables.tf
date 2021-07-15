variable "vpc_all" {

}

variable "bastion_cidr" {

}

variable "public_cidrs" {
  type = list(string)
}

variable "subnet_set_name" {

}

variable "user_data" {

}
#
variable "task_definition" {

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
}

variable "container_memory" {
  description = "Container instance memory to provision (in MiB)"
}

variable "server_port" {

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

variable "environment" {

}

variable "tags_common" {
  type = map(string)
}
