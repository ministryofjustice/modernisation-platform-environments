variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = "IPv4 CIDRs allowed through the shared prototype edge WAF; matches the web-ui builder ALB allow-list (MoJ GlobalProtect / Prisma Access egress)."
  default = [
    "18.169.147.172/32", # MoJ core-network-services NAT (eu-west-2a)
    "35.176.93.186/32",  # MoJ core-network-services NAT (eu-west-2b)
    "18.130.148.126/32", # MoJ core-network-services NAT (eu-west-2c)
    "35.176.148.126/32", # MoJ core-network-services NAT (HA)
    "128.77.75.64/26",   # Palo Alto Networks Prisma Access (MoJ GP cloud gw)
  ]
}
