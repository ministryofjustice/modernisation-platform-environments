locals {
    # Global Protect Alpha VPN gateways - RADIUS portal access
  global_protect_alpha_vpn_cidrs = [
    "35.176.93.186/32",      # Global Protect Gateway
    "18.130.148.126/32",     # Global Protect 3rd Gateway
    "35.176.148.126/32",     # Global Protect 4th Gateway
    "18.169.147.172/32",     # Global Protect 2nd Gateway
  ]
}