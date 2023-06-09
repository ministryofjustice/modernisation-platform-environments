variable "application_name" { 
  default = "ossc"
}

variable "environment" {
  type = string
  #default = "development"
}

variable app_db_name {
  default = "ossc"
}  

variable app_db_login_name {
  default = "ossc-app"
}  

#variable "db_instance_identifier" {  
#}

variable "rds_url" {  
  type = string
}

variable "rds_user" {  
  type = string
}

variable "rds_password" {  
  type = string
}

variable "source_db_url" {  
  type = string
}

variable "source_db_user" {  
  type = string
}

variable "source_db_password" {  
  type = string
}

variable "replication_instance_arn" {
}