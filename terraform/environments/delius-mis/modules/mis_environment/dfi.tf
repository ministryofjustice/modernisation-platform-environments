resource "aws_security_group" "dfi_ec2" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name        = "${var.app_name}-${var.env_name}-dfi-ec2-instance-sg"
  description = "Security group for DFI EC2"
  vpc_id      = var.account_info.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.env_name}-dfi-ec2-instance-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "dfi_ec2" {
  for_each = {
    http8080-from-alb = { referenced_security_group_id = aws_security_group.mis_alb.id, ip_protocol = "tcp", port = 8080 }
  }

  description       = each.key
  security_group_id = resource.aws_security_group.dfi_ec2.id

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "-1")
  from_port                    = lookup(each.value, "port", lookup(each.value, "from_port", null))
  to_port                      = lookup(each.value, "port", lookup(each.value, "to_port", null))
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "dfi_ec2" {
  for_each = {
    smtp-to-internal  = { ip_protocol = "TCP", port = 25, cidr_ipv4 = "10.0.0.0/8" }
    http-to-all       = { ip_protocol = "TCP", port = 80, cidr_ipv4 = "0.0.0.0/0" }
    ntp-to-all        = { ip_protocol = "UDP", port = 123, cidr_ipv4 = "0.0.0.0/0" }
    https-to-all      = { ip_protocol = "TCP", port = 443, cidr_ipv4 = "0.0.0.0/0" }
    smb-to-fsx        = { ip_protocol = "TCP", port = 445, referenced_security_group_id = aws_security_group.fsx.id }
    oracle1521-to-vpc = { ip_protocol = "TCP", port = 1521, cidr_ipv4 = module.ip_addresses.mp_cidr[local.vpc_name] }
  }

  description       = each.key
  security_group_id = resource.aws_security_group.dfi_ec2.id

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "-1")
  from_port                    = lookup(each.value, "port", lookup(each.value, "from_port", null))
  to_port                      = lookup(each.value, "port", lookup(each.value, "to_port", null))
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = var.tags
}

#FIXME: delete
resource "aws_security_group" "dfi" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name_prefix = "${var.env_name}-dfi"
  vpc_id      = var.account_info.vpc_id
}

module "dfi_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v4.1.0"

  # allow environment not to have this var set and still work
  count = var.dfi_config != null ? var.dfi_config.instance_count : 0

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "${var.app_name}-${var.env_name}-dfi-${count.index + 1}"

  ami_name  = var.dfi_config.ami_name
  ami_owner = "self"
  instance = merge(var.dfi_config.instance_config, {
    vpc_security_group_ids = [
      aws_security_group.legacy.id,
      aws_security_group.dfi_ec2.id,
      aws_security_group.mis_ad_join.id,
    ]
  })
  ebs_kms_key_id                = var.account_config.kms_keys["ebs_shared"]
  ebs_volumes_copy_all_from_ami = false
  ebs_volumes                   = var.dfi_config.ebs_volumes
  ebs_volume_config             = var.dfi_config.ebs_volumes_config
  ebs_volume_tags               = var.tags
  route53_records = {
    create_internal_record = false
    create_external_record = false
  }
  iam_resource_names_prefix = "${var.env_name}-dfi-${count.index + 1}"
  instance_profile_policies = [
    # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", added by module
    aws_iam_policy.secrets_manager.arn,
    aws_iam_policy.ec2_automation.arn
  ]

  user_data_raw = base64encode(
    templatefile(
      "${path.module}/templates/AutoEC2LaunchV2.yaml.tftpl",
      {
        #ad_username_secret_name = aws_secretsmanager_secret.ad_username.name
        ad_password_secret_name = aws_secretsmanager_secret.ad_admin_password.name
        ad_domain_name          = var.environment_config.ad_domain_name
        ad_ip_list              = aws_directory_service_directory.mis_ad.dns_ip_addresses
        branch                  = var.dfi_config.branch
      }
    )
  )

  business_unit     = var.account_info.business_unit
  environment       = var.account_info.mp_environment
  application_name  = var.app_name
  region            = "eu-west-2"
  availability_zone = "eu-west-2a"
  subnet_id         = var.account_config.private_subnet_ids[count.index]
  tags = merge(
    var.tags,
    {
      domain-name = var.environment_config.ad_domain_name
      server-type = "MISDis"
    }
  )
  cloudwatch_metric_alarms = var.dfi_config.cloudwatch_metric_alarms != null ? var.dfi_config.cloudwatch_metric_alarms : merge(
    local.cloudwatch_metric_alarms.ec2
  )
}
