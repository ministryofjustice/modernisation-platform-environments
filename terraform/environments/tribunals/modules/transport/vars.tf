variable "application_name" { 
  default = "transport"
}

variable "environment" {
  type = string
  #default = "development"
}

variable app_db_name {
  default = "transport"
}  

variable app_db_login_name {
  default = "transport-app"
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

variable "curserver" {
}

variable "support_team" {
}

variable "support_email" {
}

variable "moj_ip" {
}

variable "vpc_id" {
}

variable "client_id" { 
}

variable "local_tags" { 
}

variable "shared_public_ids" {  
}
