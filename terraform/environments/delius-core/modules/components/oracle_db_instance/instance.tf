locals {
  instance_config = {
    associate_public_ip_address  = false
    disable_api_termination      = false
    disable_api_stop             = false
    instance_type                = var.ec2_instance_type
    key_name                     = var.ec2_key_pair_name
    metadata_endpoint_enabled    = var.metadata_options.http_endpoint
    metadata_options_http_tokens = var.metadata_options.http_tokens
    monitoring                   = var.monitoring
    ebs_block_device_inline      = var.inline_ebs
    vpc_security_group_ids       = var.security_group_ids
    private_dns_name_options = {
      enable_resource_name_dns_aaaa_record = false
      enable_resource_name_dns_a_record    = true
      hostname_type                        = "resource-name"
    }
    tags = var.tags
  }
}

module "instance" {
  #checkov:skip=CKV_TF_1
  #checkov:skip=CKV_TF_2
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v4.1.0"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${local.instance_name_index}" # e.g. dev-boe-db-1

  ami_name                      = data.aws_ami.oracle_db.name
  ami_owner                     = var.db_ami.owner
  instance                      = local.instance_config
  ebs_kms_key_id                = var.account_config.kms_keys.general_shared
  ebs_volumes_copy_all_from_ami = true
  ebs_volume_config             = var.ebs_volume_config
  ebs_volumes                   = var.ebs_volumes
  ebs_volume_tags               = var.tags
  # route53_records               = merge(local.ec2_test.route53_records, lookup(each.value, "route53_records", {})) # revist
  route53_records = {
    create_internal_record = false
    create_external_record = false
  }
  iam_resource_names_prefix = "instance"
  instance_profile_policies = var.instance_profile_policies

  user_data_raw = base64encode(
    templatefile(
      "${path.module}/templates/concatenated_user_data.sh",
      {
        default   = var.user_data,
        ssh_setup = file("${path.module}/templates/ssh_key_setup.sh"),
      }
    )
  )

  business_unit     = var.account_info.business_unit
  application_name  = var.account_info.application_name
  environment       = var.account_info.mp_environment
  region            = "eu-west-2"
  availability_zone = var.availability_zone
  subnet_id         = var.subnet_id
  tags = merge(var.tags,
    { Name = "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${local.instance_name_index}" },
    { server-type = var.server_type_tag },
    { database = local.database_tag },
    var.enable_platform_backups != null ? { "backup" = var.enable_platform_backups ? "true" : "false" } : {}
  )

  cloudwatch_metric_alarms = var.enable_cloudwatch_alarms ? merge(
    local.cloudwatch_metric_alarms.ec2
  ) : {}
}
