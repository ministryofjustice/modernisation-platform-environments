resource "aws_security_group" "dfi" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name_prefix = "${var.env_name}-dfi"
  vpc_id      = var.account_info.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "dfi_oracle_db" {
  description                  = "Oracle DB connection to DSD database"
  security_group_id            = aws_security_group.dfi.id
  referenced_security_group_id = data.aws_security_group.dsd_db.id
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1521
}

resource "aws_vpc_security_group_egress_rule" "dfi_all_outbound" {
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.dfi.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_security_group" "dsd_db" {
  name = "delius-mis-${var.env_name}-dsd-db-ec2-instance-sg"
}

module "dfi_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v3.0.1"

  count = var.dfi_config != null ? var.dfi_config.instance_count : 0

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "${var.app_name}-${var.env_name}-dfi-${count.index + 1}"

  ami_name  = var.dfi_config.ami_name
  ami_owner = "self"
  instance = merge(
    var.dfi_config.instance_config,
    { vpc_security_group_ids = [aws_security_group.legacy.id, aws_security_group.dfi.id, aws_security_group.mis_ec2_shared.id] }
  )
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
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
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
        branch                  = "TM/TM-1305/MIS-auto-config"
      }
    )
  )

  business_unit     = var.account_info.business_unit
  environment       = var.account_info.mp_environment
  application_name  = var.app_name
  region            = "eu-west-2"
  availability_zone = "eu-west-2a"
  subnet_id         = var.account_config.private_subnet_ids[count.index]
  tags              = merge(
    var.tags,
    {
        domain-name = var.environment_config.ad_domain_name
    }
  )
  cloudwatch_metric_alarms = {}
}
