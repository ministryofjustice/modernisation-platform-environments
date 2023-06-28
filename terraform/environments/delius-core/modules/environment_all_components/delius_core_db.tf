module "ec2_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v2.0.0"

  business_unit    = var.account_info.business_unit # hmpps
  application_name = var.account_info.application_name # delius-core
  region           = var.account_info.region # eu-west-2
  mp_environment   = var.account_info.environment # equates to one of the 4 MP environment names, e.g. development

  ami_name  = var.db_config.ami_name # delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z
  ami_owner = local.environment_management.account_ids["core-shared-services-production"]} # 

  associate_public_ip_address  = false
  disable_api_termination      = true
  instance_type                = "r6i.xlarge"
  key_name                     = string
    metadata_endpoint_enabled    = optional(string, "enabled")
    metadata_options_http_tokens = optional(string, "required")
    monitoring                   = optional(bool, true)
    ebs_block_device_inline      = optional(bool, false)
    vpc_security_group_ids       = list(string)
    private_dns_name_options = optional(object({
      enable_resource_name_dns_aaaa_record = optional(bool)
      enable_resource_name_dns_a_record    = optional(bool)
      hostname_type                        = string
    }))
  })
}



