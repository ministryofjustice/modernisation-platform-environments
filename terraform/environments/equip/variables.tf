variable "ingress_rules_dc_tcp" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [135, 137, 139, 445, 389, 636, 3268, 3269, 88, 53, 1512, 42]
}
