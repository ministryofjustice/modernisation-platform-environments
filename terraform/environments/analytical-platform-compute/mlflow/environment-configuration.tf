locals {
  environment_configurations = {
    development = {
      mlflow_s3_bucket_name = "alpha-analytical-platform-mlflow-development"
      route53_zone          = "compute.development.analytical-platform.service.justice.gov.uk"

      # CIDRs allowed to reach MLflow; joined into the ingress
      # whitelist-source-range annotation (values.yml.tftpl).
      mlflow_ingress_allowlist = [
        "128.77.75.64/26", # Prisma Corporate
        # GlobalProtect (Alpha)
        "35.176.93.186/32",
        "18.169.147.172/32",
        "18.130.148.126/32",
        "35.176.148.126/32",
        # Elastic IPs for the Legacy Production NAT Gateways
        "54.195.74.96/32",
        "63.35.122.32/32",
        "79.125.36.56/32",
        # Elastic IPs for the Production Analytical Platform Compute NAT Gateways
        "18.168.85.104/32",
        "13.42.220.232/32",
        "18.168.158.203/32",
      ]
    }
    test = {
    }
    production = {
    }
  }
}
