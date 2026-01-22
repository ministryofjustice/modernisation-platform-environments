module "network_firewall_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases               = ["network-firewall/${local.application_name}-${local.environment}"]
  enable_default_policy = true

  deletion_window_in_days = 7
}
