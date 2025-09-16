#Variables
variable "env" { 
    type = string
}
    
variable "region" {
    default = "eu-west-2"
}

variable "scope"{
    default = "REGIONAL"
}

variable "web_acl_name" { 
    type = string
    default = "ebs_waf"
}

variable "web_acl_id" { 
    type = string
}

variable "rule_name" {
    default = "Allow" 
}