variable "database_name" {
  description = "Name of the database to be migrated"
  type        = string
}

variable dms_replication_instance_class {
  description = "Name of the replication instance class to be used"
  type        = string
  default     = "dms.t3.micro"
}

variable dms_availability_zone {
  description = "Replication Instance AZ"
  type        = string
  default     = "eu-west-2b"  
}

variable dms_engine_version {
  description = "Replication Instance Engine Version"
  type        = string
  default     = "3.5.1"   
}

variable "rds_db_security_group_id" {
  description = "Security Group associated to RDS Database Instance"
  type        = string 
}

variable "rds_db_instance" {
  description = "Name of the RDS Database Instance"
  type        = string
  default     = "database_2022" 
}

variable "rds_db_instance_pasword" {
  description = "Password for the RDS Database Instance"
  type        = string  
}

variable "rds_db_instance_port" {
  description = "Logical port number for the RDS Database Instance"
  type        = number  
}

variable "rds_db_server_name" {
  description = "RDS Database Instance endpoint"
  type        = string  
}

variable "rds_db_username" {
  description = "Username to login to RDS Database Instance"
  type        = string  
}

variable "dms_vpc_id" {
  description = "VPC ID same as that of the existing RDS Database instance"
  type        = string  
}