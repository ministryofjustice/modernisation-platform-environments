################################################################################
# WAF
################################################################################

variable "waf_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "associate_web_acl" {
  description = "Indicates whether a Web Application Firewall (WAF) ACL should be associated with the load balancer"
  type        = bool
  default     = false
}

variable "web_acl_arn" {
  description = "Web Application Firewall (WAF) ARN of the resource to associate with the load balancer"
  type        = string
  default     = null
}

variable "additional_waf_rules" {
  description = "Additional WAF rules to add to the default WAF rules"
  type = list(object({
    name     = string
    priority = number
    arn      = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "waf_IP_rules" {
  description = "A map of IP sets to create"
  type = map(object({
    name         = string
    priority     = number
    description  = string
    ip_addresses = list(string)
  }))
  default = {}
}

variable "waf_geoIP_rules" {
  description = "A list of GeoIP rules to add to the waf"
  type = list(object({
    name     = string
    priority = number
    geo_match_statement = object({
      country_codes = list(string)
    })
  }))
  default = []

}

variable "scope" {
  description = "The scope of the WAF"
  type        = string
  default     = "REGIONAL"
}

variable "region" {
  description = "The region to deploy the WAF in"
  type        = string
  default     = "eu-west-2"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN to encrypt CloudWatch log groups"
}

variable "kms_key_id" {
  type        = string
  description = "KMS Key ID to encrypt CloudWatch log groups"
  default     = null
}

variable "kms_key_us_east_1" {
  type        = string
  description = "KMS Key ARN for CloudFront WAF logs in us-east-1"
}