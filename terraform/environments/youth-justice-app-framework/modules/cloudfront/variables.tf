variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "cloudfront_default_cache_behavior" {
  description = "A map of default cache behavior settings"
  type        = map(map(string))
  default     = {}
}

variable "alb_dns" {
  description = "The DNS name of the ALB to associate with the CloudFront distribution"
  type        = string
}

variable "cloudfront_alias" {
  description = "The alias to use for the CloudFront distribution"
  type        = string
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "The ID of the WAF Web ACL to associate with the CloudFront distribution"
  type        = string
}

variable "r53_zone_id" {
  description = "The ID of the Route 53 hosted zone to use for DNS validation"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encryption"
  type        = string
}

variable "cloudfront_route53_record_name" {
  description = "The name of the Route 53 record to create for the CloudFront distribution"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  type        = string
}