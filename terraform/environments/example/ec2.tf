###########################################################################################
#------------------------Comment out file if not required----------------------------------
###########################################################################################

# EC2 Created via module
module "ec2_test_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }
  for_each                      = try(local.ec2_test.ec2_test_instances, {})
  name                          = each.key
  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.instance, lookup(each.value, "instance", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = lookup(each.value, "ssm_parameters_prefix", "test/")
  ssm_parameters                = lookup(each.value, "ssm_parameters", null)
  route53_records               = merge(local.ec2_test.route53_records, lookup(each.value, "route53_records", {}))

  iam_resource_names_prefix = "ec2-test-instance"
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit            = local.business_unit
  application_name         = local.application_name
  environment              = local.environment
  region                   = local.region
  availability_zone        = local.availability_zone_1
  subnet_id                = module.environment.subnet["private"][local.availability_zone_1].id
  tags                     = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup       = local.environment_management.account_ids
  cloudwatch_metric_alarms = {}
}

# EC2 Sec Group
resource "aws_security_group" "example_ec2_sg" {
  name        = "example_ec2_sg"
  description = "Controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_traffic" {
  for_each          = local.application_data.example_ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example_ec2_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_traffic" {
  for_each                 = local.application_data.example_ec2_sg_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.example_ec2_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.example_ec2_sg.id
}

#  Build EC2 "example-ec2"
resource "aws_instance" "develop" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type          = local.application_data.accounts[local.environment].instance_type
  ami                    = local.application_data.accounts[local.environment].ami_image_id
  vpc_security_group_ids = [aws_security_group.example_ec2_sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  monitoring             = true
  ebs_optimized          = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-example", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.example_ec2_sg]
}

# create single managed policy
resource "aws_iam_policy" "ec2_common_policy" {
  name        = "ec2-common-policy"
  path        = "/"
  description = "Common policy for all ec2 instances"
  policy      = data.aws_iam_policy_document.ec2_common_combined.json
  tags = merge(
    local.tags,
    {
      Name = "ec2-common-policy"
    },
  )
}

# combine ec2-common policy documents
data "aws_iam_policy_document" "ec2_common_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.ec2_policy.json,
  ]
}

# create list of common managed policies that can be attached to ec2 instance profiles
locals {
  ec2_common_managed_policies = [
    aws_iam_policy.ec2_common_policy.arn
  ]
  instance = {
    disable_api_termination      = false
    instance_type                = "t3.medium"
    key_name                     = try(aws_key_pair.ec2-user.key_name)
    monitoring                   = false
    metadata_options_http_tokens = "required"
    vpc_security_group_ids       = try([aws_security_group.example_ec2_sg.id])
  }
}

# custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
data "aws_iam_policy_document" "ec2_policy" {
  statement {
    sid    = "CustomEc2Policy"
    effect = "Allow"
    actions = [
      "ec2:*"
    ]
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
}

#------------------------------------------------------------------------------
# Keypair for ec2-user
#------------------------------------------------------------------------------
resource "aws_key_pair" "ec2-user" {
  key_name   = "ec2-user"
  public_key = file(".ssh/${terraform.workspace}/ec2-user.pub")
  tags = merge(
    local.tags,
    {
      Name = "ec2-user"
    },
  )
}

# Volumes built for use by EC2.
resource "aws_kms_key" "ec2" {
  description         = "Encryption key for EBS"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ebs-kms.json

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ebs-kms"
    }
  )
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = "${local.application_data.accounts[local.environment].region}a"
  type              = "gp3"
  size              = 50
  throughput        = 200
  encrypted         = true
  kms_key_id        = aws_kms_key.ec2.arn
  tags = {
    Name = "ebs-data-volume"
  }

  depends_on = [aws_instance.develop, aws_kms_key.ec2]
}

# Attach to the EC2
resource "aws_volume_attachment" "mountvolumetoec2" {
  device_name = "/dev/sdb"
  instance_id = aws_instance.develop.id
  volume_id   = aws_ebs_volume.ebs_volume.id
}

#### This file can be used to store data specific to the member account ####
data "aws_iam_policy_document" "ebs-kms" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
      "ec2.amazonaws.com"]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
      "arn:aws:iam::${data.aws_caller_identity.original_session.id}:root"]
    }
  }
}