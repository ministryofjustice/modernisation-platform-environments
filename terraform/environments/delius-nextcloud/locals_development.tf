# Terraform configuration data for environments in delius-mis development account

locals {
  environment_config_dev = {
    legacy_engineering_vpc_cidr = "10.161.98.0/25"
    legacy_counterpart_vpc_cidr = "10.162.32.0/20"
  }

  bastion_config_dev = {
    extra_user_data_content = "yum install -y openldap-clients"
  }

  nextcloud_config_dev = {
    image_tag = "latest"
  }

}
