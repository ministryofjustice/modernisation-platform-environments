#resource "aws_instance" "db_ec2" {
#  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
#  instance_type               = var.ec2_instance_type
#  ami                         = data.aws_ami.oracle_db.id
#  vpc_security_group_ids      = var.security_group_ids
#  subnet_id                   = var.subnet_id
#  iam_instance_profile        = var.instance_profile.name
#  associate_public_ip_address = false
#  monitoring                  = var.monitoring
#  ebs_optimized               = true
#  key_name                    = var.ec2_key_pair_name
#  user_data_base64 = base64encode(templatefile("${path.module}/templates/concatenated_user_data.sh",
#    {
#      default   = var.user_data
#      ssh_setup = templatefile("${path.module}/templates/ssh_key_setup.sh", { aws_region = "eu-west-2", bucket_name = var.ssh_keys_bucket_name })
#    }
#  ))
#
#  metadata_options {
#    http_endpoint = var.metadata_options.http_endpoint
#    http_tokens   = var.metadata_options.http_tokens
#  }
#
#  root_block_device {
#    volume_type = var.ebs_volumes.root_volume.volume_type
#    volume_size = var.ebs_volumes.root_volume.volume_size
#    iops        = var.ebs_volumes.iops
#    throughput  = var.ebs_volumes.throughput
#    encrypted   = true
#    kms_key_id  = var.ebs_volumes.kms_key_id
#    tags        = var.tags
#  }
#
#  # dynamic "ephemeral_block_device" {
#  #   for_each = { for k, v in var.ebs_volumes.ebs_non_root_volumes : k => v if v.no_device == true }
#  #   content {
#  #     device_name = ephemeral_block_device.key
#  #     no_device   = true
#  #   }
#  # }
#
#  tags = merge(var.tags,
#    { Name = lower(format("%s-delius-db-%s", var.env_name, local.instance_name_index)) },
#    { server-type = "delius_core_db" },
#    { database = local.database_tag }
#  )
#
#  user_data_replace_on_change = var.user_data_replace_on_change
#}

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
    ebs_block_device_inline      = true
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
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = lower(format("%s-delius-db-%s", var.env_name, local.instance_name_index))

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

  user_data_raw = base64encode(var.user_data)

  business_unit     = var.account_info.business_unit
  application_name  = var.account_info.application_name
  environment       = var.account_info.mp_environment
  region            = "eu-west-2"
  availability_zone = var.availability_zone
  subnet_id         = var.subnet_id
  tags = merge(var.tags,
    { Name = lower(format("%s-delius-db-%s", var.env_name, local.instance_name_index)) },
    { server-type = "delius_core_db" },
    { database = local.database_tag }
  )
  #  cloudwatch_metric_alarms = {}
}