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

# (Optional) tweak times
variable "cron_block" { 
    default = "cron(0 19 ? * MON-SUN *)"
}
variable "cron_allow" {
    default = "cron(0 7 ? * MON-SUN *)"
 }
