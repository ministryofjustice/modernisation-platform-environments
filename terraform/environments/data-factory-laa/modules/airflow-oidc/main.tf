/**
  * This module creates an OIDC provider for the analytical platform compute cluster.
  * It uses the OIDC issuer URL and thumbprint for the current environment.
  * The OIDC provider is used to allow the cluster to assume IAM roles in Modernisation Platform accounts.
  */

locals {
  analytical_platform_compute_oidc_ids = {
    development   = "1972AFFBD0701A0D1FD291E34F7D1287"
    preproduction = "9FAFCA50C4DA68A8E75FD21EA53A4F2B"
    production    = "801920EDEF91E3CAB03E04C03A2DE2BB"
  }
  _current_env = reverse(split("-", terraform.workspace))[0]
  # Fall back to development if workspace is test
  current_env = local._current_env == "test" ? "development" : local._current_env

  oidc_current_env = local.analytical_platform_compute_oidc_ids[local.current_env]
}

data "tls_certificate" "analytical_platform_compute" {
  url = "https://oidc.eks.eu-west-2.amazonaws.com/id/${local.oidc_current_env}"
}

resource "aws_iam_openid_connect_provider" "analytical_platform_compute" {
  url             = "https://oidc.eks.eu-west-2.amazonaws.com/id/${local.oidc_current_env}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.analytical_platform_compute.certificates[0].sha1_fingerprint]
}
