resource "aws_security_group" "bws_ec2" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name        = "${var.app_name}-${var.env_name}-bws-ec2-instance-sg"
  description = "Security group for BWS EC2"
  vpc_id      = var.account_info.vpc_id

  tags = merge(local.tags, {
    Name = "${var.app_name}-${var.env_name}-bws-ec2-instance-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "bws_ec2" {
  for_each = {
    http7777-from-alb = { referenced_security_group_id = aws_security_group.mis_alb.id, ip_protocol = "tcp", port = 7777 }
  }

  description       = each.key
  security_group_id = resource.aws_security_group.bws_ec2.id

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "-1")
  from_port                    = lookup(each.value, "port", lookup(each.value, "from_port", null))
  to_port                      = lookup(each.value, "port", lookup(each.value, "to_port", null))
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "bws_ec2" {
  for_each = {
    all-to-bcs   = { referenced_security_group_id = aws_security_group.bcs_ec2.id }
    all-to-bps   = { referenced_security_group_id = aws_security_group.bps_ec2.id }
    http-to-all  = { ip_protocol = "TCP", port = 80, cidr_ipv4 = "0.0.0.0/0" }
    ntp-to-all   = { ip_protocol = "UDP", port = 123, cidr_ipv4 = "0.0.0.0/0" }
    https-to-all = { ip_protocol = "TCP", port = 443, cidr_ipv4 = "0.0.0.0/0" }
  }

  description       = each.key
  security_group_id = resource.aws_security_group.bws_ec2.id

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "-1")
  from_port                    = lookup(each.value, "port", lookup(each.value, "from_port", null))
  to_port                      = lookup(each.value, "port", lookup(each.value, "to_port", null))
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = local.tags
}

module "bws_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v4.2.0"

  count = var.bws_config.instance_count

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "${var.app_name}-${var.env_name}-bws-${count.index + 1}"

  ami_name  = var.bws_config.ami_name
  ami_owner = var.bws_config.ami_owner
  instance = merge(var.bws_config.instance_config, {
    key_name = aws_key_pair.ec2_user_key_pair.key_name
    vpc_security_group_ids = [
      aws_security_group.legacy.id,
      aws_security_group.bws_ec2.id,
    ]
  })
  ebs_kms_key_id                = var.account_config.kms_keys["ebs_shared"]
  ebs_volumes_copy_all_from_ami = false
  ebs_volumes                   = var.bws_config.ebs_volumes
  ebs_volume_config             = var.bws_config.ebs_volumes_config
  ebs_volume_tags               = local.tags
  route53_records = {
    create_internal_record = false
    create_external_record = false
  }
  iam_resource_names_prefix = "${var.env_name}-bws-${count.index + 1}"
  instance_profile_policies = [
    # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", added by module
    aws_iam_policy.secrets_manager.arn,
    aws_iam_policy.business_unit_kms_key_access[0].arn,
    aws_iam_policy.ec2_automation.arn,
  ]

  user_data_cloud_init = {
    args = {
      branch       = var.bws_config.ansible_branch
      ansible_args = "--tags ec2provision"
    }
    scripts = [ # paths are relative to templates/ dir
      "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
      "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
    ]
  }

  business_unit     = var.account_info.business_unit
  environment       = var.account_info.mp_environment
  application_name  = var.app_name
  region            = "eu-west-2"
  availability_zone = "eu-west-2${lookup(local.availability_zone_map, count.index % 3, "a")}"
  subnet_id         = var.account_config.ordered_private_subnet_ids[count.index % 3]
  tags = merge(local.tags, {
    instance-scheduling = "skip-scheduling"
    server-type         = "delius-bip-web"
  })

  cloudwatch_metric_alarms = merge(
    local.cloudwatch_metric_alarms.ec2
  )
}
