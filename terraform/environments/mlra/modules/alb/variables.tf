variable "account_number" {
  type        = string
  description = "Account number of current environment"
}
variable "tags" {
  type        = map(string)
  description = "Common tags to be used by all resources"
}

variable "environment" {}

variable "application_name" {
  type        = string
  description = "Name of application"
}
variable "business_unit" {
  type        = string
  description = "Business unit for the domain name"
}
variable "public_subnets" {
  type        = list(string)
  description = "Public subnets"
}
variable "private_subnets" {
  type        = list(string)
  description = "Private subnets"
}
variable "vpc_all" {
  type        = string
  description = "The full name of the VPC (including environment) used to create resources"
}
variable "enable_deletion_protection" {
  type        = bool
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer."
}
variable "region" {
  type        = string
  description = "AWS Region where resources are to be created"
}
variable "idle_timeout" {
  type        = string
  description = "The time in seconds that the connection is allowed to be idle."
}
variable "force_destroy_bucket" {
  type        = bool
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}
variable "security_group_ingress_from_port" {
  type        = string
  description = "The from port for the lb ingress rules"
}
variable "security_group_ingress_to_port" {
  type        = string
  description = "The to port for the lb ingress rules"
}
variable "security_group_ingress_protocol" {
  type        = string
  description = "The protocol for the lb ingress rules"
}
variable "moj_vpn_cidr_block" {
  type        = string
  description = "The cidr block for the lb ingress rules from MoJ VPN"
}
variable "listener_port" {
  type        = string
  description = "The port number for the ALB Listener"
}
variable "listener_protocol" {
  type        = string
  description = "The protocol for the ALB Listener"
}
variable "alb_ssl_policy" {
  type        = string
  description = "Name of the SSL Policy for the listener"
}
variable "services_zone_id" {
  type        = string
  description = "Zone Id of the Network Services for the Route 53 records"
}
variable "external_zone_id" {
  type        = string
  description = "Zone Id of the External for the Route 53 records"
}
variable "target_group_port" {
  type        = string
  description = "The port number for the ALB Target Group"
}
variable "target_group_protocol" {
  type        = string
  description = "The protocol for the ALB Target Group"
}
variable "vpc_id" {
  type        = string
  description = "The id for the VPC"
}
variable "target_group_deregistration_delay" {
  type        = string
  description = "The time in seconds for the deregistration delay"
}
variable "healthcheck_interval" {
  type        = string
  description = "The time in seconds for the health check interval"
}
variable "healthcheck_path" {
  type        = string
  description = "The path value for the health check"
}
variable "healthcheck_protocol" {
  type        = string
  description = "The protocol for the health check"
}
variable "healthcheck_timeout" {
  type        = string
  description = "The tiomeout in seconds for the health check"
}
variable "healthcheck_healthy_threshold" {
  type        = string
  description = "The healthy threshold in seconds for the health check"
}
variable "healthcheck_unhealthy_threshold" {
  type        = string
  description = "The unhealthy threshold in seconds for the health check"
}
variable "stickiness_enabled" {
  type        = bool
  description = "The enabled setting for the stickiness"
}
variable "stickiness_type" {
  type        = string
  description = "The type setting for the stickiness"
}
variable "stickiness_cookie_duration" {
  type        = string
  description = "The cookie duration in seconds for the stickiness"
}
variable "existing_bucket_name" {
  type        = string
  default     = ""
  description = "The name of the existing bucket name. If no bucket is provided one will be created for them"
}
variable "acm_cert_domain_name" {
  type        = string
  description = "The domain name of the ACM certificate for CloudFront and ALB HTTPS Listener"
}
variable "cloudfront_default_cache_behavior" {
  type        = any
  description = "Default cache behavior map for the distribution"
}
variable "cloudfront_ordered_cache_behavior" {
  type        = any
  description = "Ordered cache behavior map for the distribution, in order of precedence"
}
variable "cloudfront_origin_protocol_policy" {
  type        = string
  description = "Origin protocol policy to apply to your origin. One of http-only, https-only, or match-viewer"
}
variable "cloudfront_origin_read_timeout" {
  type        = string
  description = "The Custom Read timeout, in seconds"
}
variable "cloudfront_origin_keepalive_timeout" {
  type        = string
  description = "The Custom KeepAlive timeout, in seconds"
}
variable "cloudfront_http_version" {
  type        = string
  description = "Maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3 and http3"
}
variable "cloudfront_enabled" {
  type        = string
  description = "Whether the distribution is enabled to accept end user requests for content"
}
variable "cloudfront_price_class" {
  type        = string
  description = "Price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100"
}
variable "cloudfront_geo_restriction_type" {
  type        = string
  description = "Method that you want to use to restrict distribution of your content by country: none, whitelist, or blacklist"
}
variable "cloudfront_geo_restriction_location" {
  type        = list
  description = "ISO 3166-1-alpha-2 codes for which you want CloudFront either to distribute your content (whitelist) or not distribute your content (blacklist)"
}
variable "cloudfront_is_ipv6_enabled" {
  type        = string
  description = "Whether the IPv6 is enabled for the distribution"
}
variable "waf_default_action" {
  type        = string
  description = "Specifies how you want AWS WAF to respond to requests that don't match the criteria in any of the rules. e.g. ALLOW or BLOCK"
}
