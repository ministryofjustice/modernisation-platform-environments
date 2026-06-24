variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "hostzones" {
  description = "In order to solve ACME Challenges certmanager creates DNS records. We should limit the scope to certain hostzones. If star (*) is used certmanager will control all hostzones"
  type        = list(string)
}