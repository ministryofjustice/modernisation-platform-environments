resource "aws_security_group" "bcs" {
  name_prefix = "bcs-"
  vpc_id      = data.aws_vpc.shared.id
}

locals {

  bcs_instance_count = 3

  bcs_instance_ebs_volumes_config = {
    encrypted  = true
    kms_key_id = data.aws
  }

  bcs_instance_volumes = {
    root = {
      device_name = "/dev/sda1"
      volume_size = 8
      volume_type = "gp2"
    }
    data = {
      device_name = "/dev/sdb"
      volume_size = 100
      volume_type = "gp2"
    }
  }

  bcs_

  bcs_instance_config = {
    associate_public_ip_address  = false
    disable_api_termination      = false
    disable_api_stop             = false
    instance_type                = "t3.micro"
    metadata_endpoint_enabled    = "enabled"
    metadata_options_http_tokens = "required"
    monitoring                   = true
    ebs_block_device_inline      = true
    vpc_security_group_ids       = [aws_security_group.bcs.id]
    private_dns_name_options = {
      enable_resource_name_dns_aaaa_record = false
      enable_resource_name_dns_a_record    = true
      hostname_type                        = "resource-name"
    }
    tags = local.tags
  }

}

module "instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance"

  count = local.bcs_instance_count

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "${local.application_name}-bcs-{count.index + 1}"

  ami_name                      = "delius-core-db"
  ami_owner                     = "self"
  instance                      = local.bcs_instance_config
  ebs_kms_key_id                = data.aws_kms_key.ebs_shared.id
  ebs_volumes_copy_all_from_ami = true
  ebs_volume_config             = local.bcs_instance_ebs_volumes_config
  ebs_volumes                   = var.bcs_instance_ebs_volumes
  ebs_volume_tags               = local.tags
  route53_records = {
    create_internal_record = false
    create_external_record = false
  }
  iam_resource_names_prefix = "instance-bcs${count.index + 1}-"
  instance_profile_policies = local.bcs_instance_profile_policies

  user_data_raw = base64encode(var.user_data)

  business_unit     = var.networking[0].business-unit
  application_name  = local.application_name
  environment       = terraform.workspace
  region            = "eu-west-2"
  availability_zone = "eu-west-2a"
  subnet_id         = data.aws_subnets.shared-private[0].id
  tags = local.tags }
  )
  #  cloudwatch_metric_alarms = {}
}