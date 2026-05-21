locals {
  environment_configurations = {
    development = {
      endpoint_public_access_cidrs = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
      ]
    }
    test = {
      endpoint_public_access_cidrs = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
      ]
    }
    preproduction = {
      endpoint_public_access_cidrs = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
      ]
    }
    production = {
      endpoint_public_access_cidrs = [
        # VPN
        "128.77.75.64/26",  # Prisma Corporate
        "35.176.93.186/32", # GlobalProtect (Alpha)
      ]
    }
  }
}
