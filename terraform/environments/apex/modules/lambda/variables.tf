variable "backup_policy_name" {
  type        = string
  default     = ""
}

variable "role" {
  type        = string
  default     = ""
}

variable "tags" {
  type        = map(any)
}

variable "filename" {
  type    = list(string)
  default = [""]
}

variable "source_file" {
  type        = list(string)
  default     = [""]                       
}

variable "output_path" {
  type        = list(string)
  default     = [""]            
}

variable "function_name" {
  type        = list(string)
  default     = [""]
}

variable "handler" {
  type        = list(string)
  default     = [""]      
}

variable "runtime" {
  type        = list(string)
  default     = [ ""]              
}

variable "security_grp_name" {
  type = string
  default = ""
}