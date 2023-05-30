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

variable "db_instance_identifier" {  
}

variable "rds_secret_arn" {  
}