locals {
  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
    id               = data.aws_caller_identity.current.account_id
    cp_cidr          = "172.20.0.0/16"
  }

  account_config = {
    shared_vpc_cidr               = data.aws_vpc.shared.cidr_block
    private_subnet_ids            = data.aws_subnets.shared-private.ids
    public_subnet_ids             = data.aws_subnets.shared-public.ids
    ordered_private_subnet_ids    = local.ordered_subnet_ids
    ordered_subnets               = [local.ordered_subnet_ids]
    subnet_set                    = local.subnet_set
    data_subnet_ids               = data.aws_subnets.shared-data.ids
    data_subnet_a_id              = data.aws_subnet.data_subnets_a.id
    route53_inner_zone            = data.aws_route53_zone.inner
    route53_network_services_zone = data.aws_route53_zone.network-services
    route53_external_zone         = data.aws_route53_zone.external
    shared_vpc_id                 = data.aws_vpc.shared.id
    kms_keys = {
      ebs_shared     = data.aws_kms_key.ebs_shared.arn
      general_shared = data.aws_kms_key.general_shared.arn
      rds_shared     = data.aws_kms_key.rds_shared.arn
    }
    dns_suffix = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  }

  platform_vars = {
    environment_management = local.environment_management
  }

  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  integration_key_lookup     = local.is-production ? "delius_mis_prod_alarms" : "delius_mis_nonprod_alarms"
  pagerduty_integration_key  = local.pagerduty_integration_keys[local.integration_key_lookup]

  domain_join_ports = [
    { protocol = "tcp", from_port = 25, to_port = 25 },
    { protocol = "tcp", from_port = 53, to_port = 53 }, # DNS
    { protocol = "udp", from_port = 53, to_port = 53 },
    { protocol = "udp", from_port = 67, to_port = 67 },
    { protocol = "tcp", from_port = 88, to_port = 88 }, # Kerberos
    { protocol = "udp", from_port = 88, to_port = 88 },
    { protocol = "udp", from_port = 123, to_port = 123 }, # NTP
    { protocol = "tcp", from_port = 135, to_port = 135 }, # RPC
    { protocol = "udp", from_port = 137, to_port = 138 }, # NetBIOS
    { protocol = "tcp", from_port = 139, to_port = 139 }, # NetBIOS
    { protocol = "tcp", from_port = 389, to_port = 389 }, # LDAP
    { protocol = "udp", from_port = 389, to_port = 389 },
    { protocol = "tcp", from_port = 445, to_port = 445 }, # SMB
    { protocol = "udp", from_port = 445, to_port = 445 },
    { protocol = "tcp", from_port = 464, to_port = 464 }, # Kerberos password change
    { protocol = "udp", from_port = 464, to_port = 464 },
    { protocol = "tcp", from_port = 636, to_port = 636 }, # LDAPS
    { protocol = "tcp", from_port = 1025, to_port = 5000 },
    { protocol = "udp", from_port = 2535, to_port = 2535 },
    { protocol = "tcp", from_port = 3268, to_port = 3269 },
    { protocol = "tcp", from_port = 5722, to_port = 5722 },
    { protocol = "tcp", from_port = 9389, to_port = 9389 },
    { protocol = "tcp", from_port = 49152, to_port = 65535 },
    { protocol = "icmp", from_port = -1, to_port = -1 } # ICMP
  ]

}
