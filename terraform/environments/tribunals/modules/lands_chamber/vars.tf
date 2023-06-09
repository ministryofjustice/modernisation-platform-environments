variable "application_name" { 
  default = "lands"
}

variable "environment" {
  type = string
  #default = "development"
}

variable app_db_name {
  default = "lands"
}  

variable app_db_login_name {
  default = "lands-app"
}  

#variable "db_instance_identifier" {  
#}

variable "rds_instance" {  
  type = aws_db_instance
}

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