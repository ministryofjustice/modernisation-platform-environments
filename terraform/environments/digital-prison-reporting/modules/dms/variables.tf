variable "name" {
  description = "DMS Replication name."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "availability_zones" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "source_address" {}

variable "vpc" {}

variable "kinesis_target_stream" {}

variable "kinesis_stream_policy" {}

variable "availability_zone" {
  default = null
}

# Used in tagginga and naming the resources

variable "stack_name" {
  description = "The name of our application"
  default     = "dblink"
}

variable "owner" {
  description = "A group email address to be used in tags"
  default     = "autobots@ga.gov.au"
}

variable "environment" {
  description = "Used for seperating terraform backends and naming items"
  default     = "prod"
}

#--------------------------------------------------------------
# DMS general config
#--------------------------------------------------------------

variable "identifier" {
  default     = "rds"
  description = "Name of the database in the RDS"
}

#--------------------------------------------------------------
# DMS target config
#--------------------------------------------------------------

variable "target_backup_retention_period" {
  # Days
  default     = "30"
  description = "Retention of RDS backups"
}

variable "target_backup_window" {
  # 12:00AM-03:00AM AEST
  default     = "14:00-17:00"
  description = "RDS backup window"
}

#variable "target_db_name" {
#  description = "Name of the target database"
#}

variable "target_db_port" {
  description = "The port the Application Server will access the database on"
  default     = 5432
}

variable "target_engine" {
  default     = "kinesis"
  description = "Engine type, example values mysql, postgres"
}

variable "target_engine_version" {
  description = "Engine version"
  default     = "9.3.14"
}

variable "target_instance_class" {
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "target_maintenance_window" {
  default     = "Mon:00:00-Mon:03:00"
  description = "RDS maintenance window"
}

#variable "target_password" {
#  description = "Password of the target database"
#}

variable "target_rds_is_multi_az" {
  description = "Create backup database in separate availability zone"
  default     = "false"
}

variable "target_storage" {
  default     = "10"
  description = "Storage size in GB"
}

variable "target_storage_encrypted" {
  description = "Encrypt storage or leave unencrypted"
  default     = false
}

#variable "target_username" {
#  description = "Username to access the target database"
#}

#--------------------------------------------------------------
# DMS source config
#--------------------------------------------------------------

variable "source_app_password" {
  description = "Password for the endpoint to access the source database"
}

variable "source_app_username" {
  description = "Username for the endpoint to access the source database"
}

variable "source_backup_retention_period" {
  # Days
  default     = "1"
  description = "Retention of RDS backups"
}

variable "source_backup_window" {
  # 12:00AM-03:00AM AEST
  default     = "14:00-17:00"
  description = "RDS backup window"
}

variable "source_db_name" {
  description = "Name of the target database"
  default     = "nomis-t3"
}

variable "source_db_port" {
  description = "The port the Application Server will access the database on"
  default     = 1521
}

variable "source_engine" {
  default     = "oracle-se2"
  description = "Engine type, example values mysql, postgres"
}

variable "source_engine_name" {
  default     = "oracle"
  description = "Engine name for DMS"
}

variable "source_engine_version" {
  description = "Engine version"
  default     = "12.1.0.2.v8"
}

variable "source_instance_class" {
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "source_maintenance_window" {
  default     = "Mon:00:00-Mon:03:00"
  description = "RDS maintenance window"
}

variable "source_password" {
  description = "Password of the source database"
  default     = ""
}

variable "source_rds_is_multi_az" {
  description = "Create backup database in separate availability zone"
  default     = "false"
}

#variable "source_snapshot" {
#  description = "Snapshot ID"
#}

variable "source_storage" {
  default     = "10"
  description = "Storage size in GB"
}

variable "source_storage_encrypted" {
  description = "Encrypt storage or leave unencrypted"
  default     = false
}

variable "source_username" {
  description = "Username to access the source database"
  default     = ""
}

#--------------------------------------------------------------
# DMS Replication Instance
#--------------------------------------------------------------

variable "replication_instance_maintenance_window" {
  description = "Maintenance window for the replication instance"
  default     = "sun:10:30-sun:14:30"
}

variable "replication_instance_storage" {
  description = "Size of the replication instance in GB"
  default     = "10"
}

variable "replication_instance_version" {
  description = "Engine version of the replication instance"
  default     = "3.4.6"
}

variable "replication_instance_class" {
  description = "Instance class of replication instance"
  default     = "dms.t2.micro"
}

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

variable "database_subnet_cidr" {
  default     = ["10.26.25.208/28", "10.26.25.224/28", "10.26.25.240/28"]
  description = "List of subnets to be used for databases"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = ""
}