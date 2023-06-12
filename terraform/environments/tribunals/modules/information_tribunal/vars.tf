variable "application_name" { 
  default = "it"
}

variable "environment" {
  type = string
  #default = "development"
}

variable app_db_name {
  default = "it"
}  

variable app_db_login_name {
  default = "it-app"
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