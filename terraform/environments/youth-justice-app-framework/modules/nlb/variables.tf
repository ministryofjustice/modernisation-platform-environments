variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment for the load balancer"
  type        = string
}

variable "vpc_id" {
  description = "The vpc id for the load balancer and target group"
  type        = string
}

variable "nlb_name" {
  description = "Name of the network load balancer"
  type        = string
}

variable "nlb_subnets_ids" {
  description = "Subnet ids to attach the NLB to, one per AZ"
  type        = list(string)
}

variable "private_ipv4_addresses" {
  description = "Static private IP to assign per subnet (subnet_id => IP), so the far side of Transit Gateway has a fixed target to route to. Leave a subnet out of the map to let AWS auto-assign its IP."
  type        = map(string)
  default     = {}
}

variable "target_alb_arn" {
  description = "ARN of the shared ALB this NLB forwards to (target_type = alb)"
  type        = string
}

variable "target_group_name_prefix" {
  description = "Prefix used to build each app's NLB target group name"
  type        = string
}

variable "apps" {
  description = "Map of app name => { listener_port, target_port, protocol }. One NLB listener + target group is created per app, all forwarding to the same target_alb_arn but on that app's own listener port on that ALB."
  type = map(object({
    listener_port = number
    target_port   = number
    protocol      = optional(string, "TCP")
  }))
}

variable "ingress_prefix_list_id" {
  description = "Managed prefix list ID allowed to reach the NLB, e.g. Juniper's AWS account range routed in over Transit Gateway"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
