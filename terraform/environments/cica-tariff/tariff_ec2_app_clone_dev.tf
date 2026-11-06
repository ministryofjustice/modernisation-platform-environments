# Clone of Development App server for POC CDI-295
resource "aws_instance" "tariff_app_dev_poc_clone" {
  count = local.environment == "development" ? 1 : 0
  # ami   = "ami-079bedd5037ad8609"
  # ami = "ami-044bcc0b671b75b6e" # CDI-319: restore from backup
  ami = "ami-0b1782be4891b79a6" # CDI-323: restore from backup
  #Ignore changes to most recent ami from data filter, as this would destroy existing instance.
  lifecycle {
    ignore_changes = [user_data] # ami removed to allow restore
  }
  associate_public_ip_address = false
  ebs_optimized               = true

  iam_instance_profile   = aws_iam_instance_profile.tariff_instance_profile.name
  instance_type          = "m5.2xlarge"
  key_name               = aws_key_pair.key_pair_app.key_name
  monitoring             = true
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [module.tariff_app_security_group[0].security_group_id]
  #vpc_security_group_ids = [aws_security_group.temp_dev_ssm_only[0].id] # TEMPORARY ASSIGNMENT

  private_ip = "10.26.32.62"

  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-app-clone", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-app-poc-clone",
    }), local.tags, local.environment != "development" ? tomap({ "backup" = "true" }) : tomap({})
  )
}
/*
# Temporary SG to restrict access to/from Clone above during configuration phase
resource "aws_security_group" "temp_dev_ssm_only" {
  count       = local.environment == "development" ? 1 : 0
  name        = "temp-ssm-only"
  description = "Allow only SSM traffic - temporary rule during Tariff App POC clone intial config"
  vpc_id      = data.aws_vpc.shared.id
}
data "aws_security_group" "core_vpc_protected" {
  provider = aws.core-vpc

  tags = {
    Name = "${local.vpc_name}-${local.environment}-int-endpoint"
  }
}
resource "aws_security_group_rule" "temp_dev_ssm_only_egress" {
  count             = local.environment == "development" ? 1 : 0
  security_group_id = aws_security_group.temp_dev_ssm_only[0].id

  description              = "${local.application_name}-app-clone_egress_to_interface_endpoints"
  type                     = "egress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "TCP"
  source_security_group_id = data.aws_security_group.core_vpc_protected.id
}
*/