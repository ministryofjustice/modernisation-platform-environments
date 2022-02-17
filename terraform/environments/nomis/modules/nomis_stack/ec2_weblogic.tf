
#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

# The security group will be common across all weblogic instances so it is
# defined outside of this module. (it is envisaged that they will be accessed
# from a single jumpserver.  Also it makes it easier to manage the loadbalancer
# egress rules if there is a single security group.)

#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------

data "aws_ami" "weblogic_image" {
  most_recent = true
  owners      = [var.weblogic_ami_owner]

  filter {
    name   = "name"
    values = [var.weblogic_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  weblogic_root_device_size = one([for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.weblogic_image.root_device_name])
}

data "template_file" "weblogic_init" {
  template = file("${path.module}/user_data/weblogic_init.sh")
  vars = {
    ENV               = var.stack_name
    WEBLOGIC_HOSTNAME = "weblogic.${var.stack_name}.${var.application_name}.${data.aws_route53_zone.internal.name}"
    DB_HOSTNAME       = "db.${var.stack_name}.${var.application_name}.${data.aws_route53_zone.internal.name}"
    USE_DEFAULT_CREDS = var.use_default_creds
  }
}

resource "aws_instance" "weblogic_server" {
  #checkov:skip=CKV_AWS_135:skip "Ensure that EC2 is EBS optimized" as not supported by t2 instances.
  # t2 was chosen as t3 does not support RHEL 6.10. Review next time instance type is changed.
  ami                         = data.aws_ami.weblogic_image.id
  associate_public_ip_address = false
  # ebs_optimized               = true
  iam_instance_profile   = var.instance_profile_weblogic_name
  instance_type          = var.weblogic_instance_type
  key_name               = var.key_name
  monitoring             = false
  subnet_id              = data.aws_subnet.private_az_a.id
  user_data              = data.template_file.weblogic_init.rendered
  vpc_security_group_ids = [var.weblogic_common_security_group_id]

  depends_on = [aws_instance.database_server]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 4
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = lookup(var.weblogic_drive_map, data.aws_ami.weblogic_image.root_device_name, local.weblogic_root_device_size)
    volume_type           = "gp3"
  }

  dynamic "ephemeral_block_device" { # block devices specified inline cannot be resized later so we need to make sure they are not mounted here
    for_each = [for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.weblogic_image.root_device_name]
    iterator = device
    content {
      device_name = device.value.device_name
      no_device   = true
    }
  }

  tags = merge(
    var.tags,
    {
      Name       = "weblogic-${var.stack_name}"
      component  = "application"
      os_type    = "Linux"
      os_version = "RHEL 6.10"
      always_on  = var.environment == "test" ? "false" : "true"
    }
  )
}

resource "aws_ebs_volume" "weblogic_ami_volume" {
  for_each = { for bdm in data.aws_ami.weblogic_image.block_device_mappings : bdm.device_name => bdm if bdm.device_name != data.aws_ami.weblogic_image.root_device_name }

  availability_zone = "${var.region}a"
  encrypted         = true
  iops              = each.value["ebs"]["iops"]
  snapshot_id       = each.value["ebs"]["snapshot_id"]
  size              = lookup(var.weblogic_drive_map, each.value["device_name"], each.value["ebs"]["volume_size"])
  type              = each.value["ebs"]["volume_type"]

  tags = merge(
    var.tags,
    {
      Name = "weblogic-${var.stack_name}-${each.value.device_name}"
    }
  )
}

resource "aws_volume_attachment" "weblogic_ami_volume" {
  for_each = aws_ebs_volume.weblogic_ami_volume

  device_name  = each.key
  volume_id    = each.value.id
  instance_id  = aws_instance.weblogic_server.id
  force_detach = true
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

resource "aws_route53_record" "weblogic_internal" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "weblogic.${var.stack_name}.${var.application_name}.${data.aws_route53_zone.internal.name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.weblogic_server.private_ip]
}

#------------------------------------------------------------------------------
# Instance IAM role extra permissions
# Temporarily allow get parameter when instance first created
# Attach policy inline on ec2-common-role
#------------------------------------------------------------------------------

resource "time_offset" "weblogic_asm_parameter" {
  # static time resource for controlling access to parameter
  offset_minutes = 30
  triggers = {
    # if the instance is recycled we reset the timestamp to give access again
    instance_id = aws_instance.weblogic_server.arn
  }
}

data "aws_iam_policy_document" "weblogic_asm_parameter" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.id}:parameter/weblogic/default/*", "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.id}:parameter/weblogic/${var.stack_name}/*"]
    condition {
      test     = "DateLessThan"
      variable = "aws:CurrentTime"
      values   = [time_offset.weblogic_asm_parameter.rfc3339]
    }
    condition {
      test     = "StringLike"
      variable = "ec2:SourceInstanceARN"
      values   = [aws_instance.weblogic_server.arn]
    }
  }
}

data "aws_iam_instance_profile" "ec2_weblogic_profile" {
  name = var.instance_profile_weblogic_name
}

resource "aws_iam_role_policy" "weblogic_asm_parameter" {
  name   = "weblogic-asm-parameter-access-${var.stack_name}"
  role   = data.aws_iam_instance_profile.ec2_weblogic_profile.role_name
  policy = data.aws_iam_policy_document.weblogic_asm_parameter.json
}
