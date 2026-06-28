variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "hostzones" {
  description = "In order to solve ACME Challenges certmanager creates DNS records. We should limit the scope to certain hostzones. If star (*) is used certmanager will control all hostzones"
  type        = list(string)
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