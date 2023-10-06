# nomis-production environment settings
locals {

  # baseline config
  production_config = {

    baseline_secretsmanager_secrets = {
      "/oracle/oem"              = local.oem_secretsmanager_secrets
      "/oracle/database/EMREP"   = local.oem_secretsmanager_secrets
      "/oracle/database/PRCVCAT" = local.oem_secretsmanager_secrets
    }

    baseline_ssm_parameters = {
      "/oracle/oem"              = local.oem_ssm_parameters_passwords
      "/oracle/database/EMREP"   = local.oem_ssm_parameters_passwords
      "/oracle/database/PRCVCAT" = local.oem_ssm_parameters_passwords
    }

    baseline_ec2_instances = {
      # prod-oem-a = merge(local.oem_ec2_default, {
      #   config = merge(local.oem_ec2_default.config, {
      #     availability_zone = "eu-west-2a"
      #   })
      #   user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
      #     args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
      #       branch = "c958e86e4b1b062ca21d46f7ff204c60377519c5" # 2023-10-04 prod ansible config
      #     })
      #   })
      # })
    }

    baseline_route53_zones = {
      "hmpps-production.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["prod-oem-a.hmpps-oem.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
