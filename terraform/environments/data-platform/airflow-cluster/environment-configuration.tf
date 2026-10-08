locals {
  environment_configurations = {
    test = {
      eks_public_access_cidrs = [
        "128.77.75.64/26", # Prisma Corporate
        "20.58.27.30/32",  # GitHub Runner (octo-production)
        # Sites
        "213.121.161.112/28", # 102PF
        "51.149.2.0/24",      # 10SC
      ]
    }
  }
}
