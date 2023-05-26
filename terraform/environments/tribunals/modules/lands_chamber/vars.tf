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

variable "db_instance_identifier" {  
}