locals {

  security_group_cidrs_devtest = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
    ])
  }
  security_group_cidrs_preprod_prod = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.prod
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
    ])
  }

  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_group_common = {

    self_ingress = {
      description = "Allow all ingress to self"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      self        = true
    }

    ssh_ingress = {
      description     = "Allow ssh ingress"
      from_port       = "22"
      to_port         = "22"
      protocol        = "TCP"
      cidr_blocks     = local.security_group_cidrs.ssh
      security_groups = []
    }

    prometheus_node_exporter_ingress = {
      description     = "Allow prometheus node exporter ingress"
      from_port       = "9100"
      to_port         = "9100"
      protocol        = "TCP"
      cidr_blocks     = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
      security_groups = []
    }

    prometheus_script_exporter_ingress = {
      description     = "Allow prometheus script exporter ingress"
      from_port       = "9172"
      to_port         = "9172"
      protocol        = "TCP"
      cidr_blocks     = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
      security_groups = []
    }

    prometheus_wmi_exporter_ingress = {
      description     = "Allow prometheus wmi exporter ingress"
      from_port       = "9182"
      to_port         = "9182"
      protocol        = "TCP"
      cidr_blocks     = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
      security_groups = []
    }

    all_egress = {
      description     = "Allow all egress"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  security_group_jumpserver = {
    ingress = [
      local.security_group_common.self_ingress,
      local.security_group_common.prometheus_node_exporter_ingress,
      local.security_group_common.prometheus_wmi_exporter_ingress,
    ]
    egress = [
      local.security_group_common.all_egress,
    ]

  }

  security_group_public = {
    ingress = [
      local.security_group_common.self_ingress,
      local.security_group_common.ssh_ingress,
      {
        description = "Allow https ingress"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        security_groups = [
          aws_security_group.jumpserver.id,
        ]
        cidr_blocks = local.security_group_cidrs.https
      },
      {
        description = "Allow http7001 ingress"
        from_port   = 7001
        to_port     = 7001
        protocol    = "tcp"
        security_groups = [
          aws_security_group.jumpserver.id,
        ]
        cidr_blocks = local.security_group_cidrs.http7xxx
      },
      {
        description = "Allow http7777 ingress"
        from_port   = 7777
        to_port     = 7777
        protocol    = "tcp"
        security_groups = [
          aws_security_group.jumpserver.id,

        ]
        cidr_blocks = local.security_group_cidrs.http7xxx
      },
    ]
    egress = [
      local.security_group_common.all_egress,
    ]
  }

  security_group_private = {
    ingress = [
      local.security_group_common.self_ingress,
      local.security_group_common.ssh_ingress,
      local.security_group_common.prometheus_node_exporter_ingress,
      local.security_group_common.prometheus_script_exporter_ingress,
      {
        description = "Allow http7001 ingress"
        from_port   = 7001
        to_port     = 7001
        protocol    = "tcp"
        security_groups = [
          aws_security_group.jumpserver.id,
          aws_security_group.public.id,
        ]
        cidr_blocks = local.security_group_cidrs.http7xxx
      },
      {
        description = "Allow http7777 ingress"
        from_port   = 7777
        to_port     = 7777
        protocol    = "tcp"
        security_groups = [
          aws_security_group.jumpserver.id,
          aws_security_group.public.id,
        ]
        cidr_blocks = local.security_group_cidrs.http7xxx
      },
    ]
    egress = [
      local.security_group_common.all_egress,
    ]
  }

  security_group_data = {

    ingress = [
      local.security_group_common.self_ingress,
      local.security_group_common.ssh_ingress,
      local.security_group_common.prometheus_node_exporter_ingress,
      local.security_group_common.prometheus_script_exporter_ingress,

      {
        description = "Allow oracle database 1521 ingress"
        from_port   = "1521"
        to_port     = "1521"
        protocol    = "TCP"
        cidr_blocks = local.security_group_cidrs.oracle_db
        security_groups = [
          aws_security_group.jumpserver.id,
          aws_security_group.private.id,
        ]
      },

      {
        description = "Allow oem agent ingress"
        from_port   = "3872"
        to_port     = "3872"
        protocol    = "TCP"
        cidr_blocks = local.security_group_cidrs.oracle_oem_agent
        security_groups = [
          aws_security_group.jumpserver.id,
          aws_security_group.private.id,
        ]
      },
    ]

    egress = [
      local.security_group_common.all_egress,
    ]
  }
}
