
variable "account_region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account_id" {
  description = "AWS Account ID."
  default     = ""
}

variable "name" {
  description = "DMS Replication name."
  default     = ""
}

variable "setup_dms_instance" {
  description = "Enable DMS Instance, True or False"
  type        = bool
  default     = false
}

variable "project_id" {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}

variable "env" {
  type        = string
  description = "Env Type"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}


variable "availability_zones" {
  default = [
    {
      0 = "eu-west-2a"
    }
  ]
}


variable "subnet_ids" {
  description = "An List of VPC subnet IDs to use in the subnet group"
  type        = list(string)
  default     = []
}

variable "vpc" {
  type        = string
  default     = ""  
}

variable "availability_zone" {
  default = null
}

variable "create" {
  default = true
}

variable "create_iam_roles" {
  default = true
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
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

#--------------------------------------------------------------
# DMS general config
#--------------------------------------------------------------

variable "identifier" {
  default     = "rds"
  description = "Name of the database in the RDS"
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
  description = "CIDR for the  VPC"
  type        = list(string)
  default     = null
}

#--------------------------------------------------------------
# DMS Task
#--------------------------------------------------------------
variable "table_mappings" {
  type        = any
  default     = ""
}

variable "replication_task_settings" {
  type        = any
  default     = {}
}

variable "rename_rule_source_schema" {
  description = "The source schema we will rename to a target output 'space'"
  type        = string
  default     = ""
}

variable "rename_rule_output_space" {
  description = "The name of the target output 'space' that the source schema will be renamed to"
  type        = string
  default     = ""
}


variable "enable_replication_task" {
  description = "Enable DMS Replication Task, True or False"
  type        = bool
  default     = false
}

variable "migration_type" {
  type        = string
  description = "DMS Migration Type"
  default     = ""
}

variable "dms_replication_instance" {
  type        = string
  default     = ""
  description = "DMS Rep Instance ARN"
}

variable "dms_source_endpoint" {
  type        = string
  default     = ""
}

variable "dms_target_endpoint" {
  type        = string
  default     = ""
}

#--------------------------------------------------------------
# DMS Endpoint
#--------------------------------------------------------------

variable "setup_dms_endpoints" {
  description = "Enable DMS Endpoints, True or False"
  type        = bool
  default     = false    
}

variable "setup_dms_nomis_endpoint" {
  type    = bool
  default = false
}

variable "setup_dms_s3_endpoint" {
  type    = bool
  default = false
}

variable "extra_attributes" {
  type    = string
  default = null
}

variable "source_db_name" {
  description = "Name of the Source database"
  default     = "oracle"
}

variable "dms_source_name" {
  type        = string
  default     = ""  
}

variable "dms_target_name" {
  type        = string
  default     = ""  
}


variable "short_name" {
  type        = string
  default     = ""  
}

variable "source_address" {
  default     = ""
  description = "Default Source Address"    
}

variable "bucket_name" {
  type        = string
  default     = ""  
}


variable "source_db_port" {
  description = "The port the Application Server will access the database on"
  default     = null
}

variable "source_engine" {
  default     = "oracle-se2"
  description = "Engine type, example values mysql, postgres"
}

variable "source_engine_name" {
  default     = ""
  description = "Engine name for DMS"
}


variable "source_app_password" {
  description = "Password for the endpoint to access the source database"
  default     = ""  
}

variable "source_app_username" {
  description = "Username for the endpoint to access the source database"
  default     = ""  
}
