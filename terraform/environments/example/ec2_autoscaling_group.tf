module "ec2_test_autoscaling_group" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-autoscaling-group"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }
  for_each = try(local.ec2_test.ec2_test_autoscaling_groups, {})
  name = each.key
  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.autoscale_instance, lookup(each.value, "instance", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = lookup(each.value, "ssm_parameters_prefix", "test/")
  ssm_parameters                = lookup(each.value, "ssm_parameters", null)
  autoscaling_group             = merge(local.ec2_test.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules         = lookup(each.value, "autoscaling_schedules", local.autoscaling_schedules_default)

  iam_resource_names_prefix = "ec2-test-asg"
  instance_profile_policies = local.ec2_autoscale_common_managed_policies
  application_name          = local.application_name
  region                    = local.region
  subnet_ids                = module.environment.subnets["private"].ids
  tags                      = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup        = local.environment_management.account_ids
  cloudwatch_metric_alarms  = {}
}

locals {
  ec2_autoscale_common_managed_policies = [
    aws_iam_policy.ec2_autoscale_policy.arn
  ]
    autoscale_instance = {
      disable_api_termination      = false
      instance_type                = "t3.medium"
      key_name                     = aws_key_pair.ec2-autoscale-user.key_name
      monitoring                   = false
      metadata_options_http_tokens = "required"
      vpc_security_group_ids       = try([aws_security_group.example_ec2_autoscale_sg.id])
    }
}

# create single managed policy
resource "aws_iam_policy" "ec2_autoscale_policy" {
  name        = "ec2-autoscale-common-policy"
  path        = "/"
  description = "Common policy for all ec2 instances"
  policy      = data.aws_iam_policy_document.ec2_autoscale_combined.json
  tags = merge(
    local.tags,
    {
      Name = "ec2-common-policy"
    },
  )
}

# combine ec2-common policy documents
data "aws_iam_policy_document" "ec2_autoscale_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.ec2_autoscale_policy.json,
  ]
}

data "aws_iam_policy_document" "ec2_autoscale_policy" {
  statement {
    sid    = "CustomEc2Policy"
    effect = "Allow"
    actions = [
      "ec2:*"
    ]
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
}

# EC2 Sec Group
resource "aws_security_group" "example_ec2_autoscale_sg" {
  name        = "example_ec2_autoscale_sg"
  description = "Controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_autoscale_traffic" {
  for_each          = local.application_data.example_ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example_ec2_autoscale_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_autoscale_traffic" {
  for_each                 = local.application_data.example_ec2_sg_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.example_ec2_autoscale_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.example_ec2_autoscale_sg.id
}


resource "aws_key_pair" "ec2-autoscale-user" {
  key_name   = "ec2-autoscale-user"
  public_key = file(".ssh/${terraform.workspace}/ec2-user.pub")
  tags = merge(
    local.tags,
    {
      Name = "ec2-autoscale-user"
    },
  )
}