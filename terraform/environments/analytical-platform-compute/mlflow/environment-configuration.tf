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
        # Elastic IPs for the Legacy Development NAT Gateways
        "3.248.51.175/32",
        "63.32.185.181/32",
        "54.217.86.185/32",
        # Elastic IPs for the Development Analytical Platform Compute NAT Gateways
        "18.133.132.50/32",
        "18.132.51.177/32",
        "13.42.93.133/32",
      ]
    }
    test = {
    }
    production = {
    }
  }
}
