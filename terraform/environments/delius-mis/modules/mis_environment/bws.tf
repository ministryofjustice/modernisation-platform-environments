resource "aws_security_group" "bws" {
  name_prefix = "${var.env_name}-bws"
  vpc_id      = var.account_info.vpc_id
}

module "bws_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance"

  count = var.bws_config.instance_count

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name = "${var.env_name}-bws-${count.index + 1}"

  ami_name  = var.bws_config.ami_name
  ami_owner = "self"
  instance = merge(
    var.bws_config.instance_config,
    { vpc_security_group_ids = [aws_security_group.legacy.id, aws_security_group.bws.id, aws_security_group.mis_ec2_shared.id] }
  )
  ebs_kms_key_id                = var.account_config.kms_keys["ebs_shared"]
  ebs_volumes_copy_all_from_ami = false
  ebs_volumes                   = var.bws_config.ebs_volumes
  ebs_volume_config             = var.bws_config.ebs_volumes_config
  ebs_volume_tags               = var.tags
  route53_records = {
    create_internal_record = false
    create_external_record = false
  }
  iam_resource_names_prefix = "${var.env_name}-bws-${count.index + 1}"
  instance_profile_policies = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    aws_iam_policy.secrets_manager.arn
  ]

  user_data_raw = base64encode(
    templatefile(
      "${path.module}/templates/EC2LaunchV2.yaml.tftpl",
      {
        ad_username_secret_name = aws_secretsmanager_secret.ad_username.name
        ad_password_secret_name = aws_secretsmanager_secret.ad_password.name
        ad_domain_name          = var.environment_config.legacy_ad_domain_name
        ad_ip_list              = var.environment_config.legacy_ad_ip_list
      }
    )
  )

  business_unit     = var.account_info.business_unit
  environment       = var.account_info.mp_environment
  application_name  = var.app_name
  region            = "eu-west-2"
  availability_zone = "eu-west-2a"
  subnet_id         = var.account_config.private_subnet_ids[count.index]
  tags              = var.tags
  #  cloudwatch_metric_alarms = {}
}
