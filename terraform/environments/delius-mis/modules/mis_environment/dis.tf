resource "aws_security_group" "dis" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name_prefix = "${var.env_name}-dis"
  vpc_id      = var.account_info.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "mis_oracle_db" {
  description                  = "Oracle DB connection to MIS database"
  security_group_id            = aws_security_group.dis.id
  referenced_security_group_id = data.aws_security_group.mis_db.id
  ip_protocol                  = "tcp"
  from_port                    = 1521
  to_port                      = 1521
}

resource "aws_vpc_security_group_egress_rule" "dis_all_outbound" {
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.dis.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_security_group" "mis_db" {
  name = "delius-mis-${var.env_name}-mis-db-ec2-instance-sg"
}

module "dis_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v4.2.0"

  # allow environment not to have this var set and still work
  count = var.dis_config != null ? var.dis_config.instance_count : 0

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "${var.app_name}-${var.env_name}-dis-${count.index + 1}"

  ami_name  = var.dis_config.ami_name
  ami_owner = "self"
  instance = merge(
    var.dis_config.instance_config,
    { vpc_security_group_ids = [aws_security_group.legacy.id, aws_security_group.dis.id, aws_security_group.mis_ec2_shared.id] }
  )
  ebs_kms_key_id                = var.account_config.kms_keys["ebs_shared"]
  ebs_volumes_copy_all_from_ami = false
  ebs_volumes                   = var.dis_config.ebs_volumes
  ebs_volume_config             = var.dis_config.ebs_volumes_config
  ebs_volume_tags               = var.tags
  route53_records = {
    create_internal_record = false
    create_external_record = false
  }
  iam_resource_names_prefix = "${var.env_name}-dis-${count.index + 1}"
  instance_profile_policies = [
    # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", added by module
    aws_iam_policy.secrets_manager.arn,
    aws_iam_policy.ec2_automation.arn
  ]

  user_data = templatefile(
    "${path.module}/templates/user-data-pwsh.yaml.tftpl", {
      branch = var.dis_config.powershell_branch
    }
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
      computer-name = "${var.dis_config.computer_name}-${count.index + 1}"
      domain-name   = var.environment_config.ad_domain_name
      server-type   = "DeliusMisDis"
    }
  )

  cloudwatch_metric_alarms = var.dis_config.cloudwatch_metric_alarms != null ? var.dis_config.cloudwatch_metric_alarms : merge(
    local.cloudwatch_metric_alarms.ec2
  )
}
