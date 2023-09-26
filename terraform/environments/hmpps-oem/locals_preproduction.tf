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
            branch = "2468978f69041b1204ffa3dc55dfb81c1a2ad3e1" # 2023-09-25 new SSM params
          })
        })
      })
      # test-oem-b = merge(local.oem_ec2_default, {
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
