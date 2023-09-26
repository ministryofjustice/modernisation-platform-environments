# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {

    baseline_ec2_instances = {
      preprod-oem-a = merge(local.oem_ec2_default, {
        config = merge(local.oem_ec2_default.config, {
          availability_zone = "eu-west-2a"
        })
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "3d2586abc9063aee8d09add6098e534962145a73" # 2023-09-26 preprod ansible config
          })
        })
      })
      # preprod-oem-b = merge(local.oem_ec2_default, {
      #   config = merge(local.oem_ec2_default.config, {
      #     availability_zone = "eu-west-2b"
      #   })
      #   user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
      #     args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
      #       branch = "main"
      #     })
      #   })
      # })
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
