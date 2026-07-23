variable "database_name" {
  description = "Name of the Glue database"
  type        = string
}
#Glue database description

variable "database_description" {
  description = "Description of the Glue database"
  type        = string
  default     = null
}

