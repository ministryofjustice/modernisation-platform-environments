# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {

    baseline_secretsmanager_secrets = {
      "/oracle/oem"               = local.oem_secretsmanager_secrets
      "/oracle/database/EMREP"    = local.oem_secretsmanager_secrets
      "/oracle/database/PPRCVCAT" = local.oem_secretsmanager_secrets
    }

    baseline_ec2_instances = {
      preprod-oem-a = merge(local.oem_ec2_default, {
        config = merge(local.oem_ec2_default.config, {
          availability_zone = "eu-west-2a"
        })
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "cb226d7bc7cbce9a252cb4ea79e237f4c074d66d" # 2023-09-27 preprod ansible config
          })
        })
      })
    }

    baseline_route53_zones = {
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["preprod-oem-a.hmpps-oem.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
