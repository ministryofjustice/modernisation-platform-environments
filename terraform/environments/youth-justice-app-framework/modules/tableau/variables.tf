variable "project_name" {
  type        = string
  description = "project name within aws"
}

variable "environment" {
  description = "Deployment environment"

  type = string
}

variable "test_mode" {
  description = "(Optional) When test mode is true the destroy command can be used to remove all items."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "User defined extra tags to be added to all resources created in the module"
  default     = {}
}


variable "vpc_id" {
  type        = string
  description = "VPC ID."
}


variable "tableau_subnet_id" {
  type        = string
  description = "ID of the Subnet where the tableau instance is to be created."
}

variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t3.nano"
}

variable "instance_volume_size" {
  description = "The size of the volumne to ba allotages to the Tableau instance."
  type        = number
  default     = 500
}

variable "instance_key_name" {
  description = "The name suffix for the Key Pair to used for the Tableau instance. It will be suxxixed woith the project and environment name."
  default = "ec2-instance-keypair"
}

variable "private_ip" {
  description = "(Optional) The IP address to be assigned to the Tablau instance. It is important to retian thins value for Tableau licencing."
  default = null
}

variable "patch_schedule" {
  description = "The required value for the PatchSchedule tag."
}

variable "availability_schedule" {
  description = "The required value for the Schedule tag."
}

#ALB Inputs
variable "alb_name" {
  description = "The name of the aplplication Load Balancer that publishes the Tableau server."
  default     = "tableau-alb"
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs to which the Tableau applcation load bbalancer will be assigned."
  type        = list(string)
}


variable "certificate_arn" {
  description = "The arn of the SSL cetificate to use for external access to Tableau."
}

#Tableau security gropup inputs
variable "directory_service_sg_id" {
  description = "The ID of the Active directory Service Security Group. Used to add a rules to aneble ldap & ldaps to AD."
}

variable "postgresql_sg_id" {
  description = "The ID of the RDS PostgreSQL Security Group. Used to add a rule to enable Tableau access to PostgreSQL."
}

variable "redshift_sg_id" {
  description = "The ID of the Redshift Serverless Security Group. Used to add a rule to enable Tableau access to Redshift."
}

# Datadog Inputs
variable "datadog-api-key-name" {
  description = "The Name of the Secret that holds the Datagog API Key."
}
