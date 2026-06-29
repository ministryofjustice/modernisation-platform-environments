variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "hostzones" {
  description = "List of Route53 Hosted Zone ARNs that cert-manager is allowed to manage for ACME DNS challenges. Format: arn:aws:route53:::hostedzone/<ZONE_ID>. Use [\"arn:aws:route53:::hostedzone/*\"] to allow all hosted zones."
  type        = list(string)

  validation {
    condition = alltrue([
      for arn in var.hostzones : can(regex("^arn:aws:route53:::hostedzone/[A-Z0-9*]+$", arn))
    ])
    error_message = "Hosted zone ARNs must be in the format 'arn:aws:route53:::hostedzone/<ZONE_ID>' or 'arn:aws:route53:::hostedzone/*' for all zones."
  }
}

variable "certman_replicas" {
  description = "Number of replicas for cert-manager deployment"
  type        = number
  default     = 1
}

variable "webhook_replicas" {
  description = "Number of replicas for cert-manager webhook deployment"
  type        = number
  default     = 1
}

variable "cainjector_replicas" {
  description = "Number of replicas for cert-manager cainjector deployment"
  type        = number
  default     = 1
}