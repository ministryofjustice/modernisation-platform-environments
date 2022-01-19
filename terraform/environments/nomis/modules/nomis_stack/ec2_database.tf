#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "database_server" {
  description = "Stack specific security group rules for database instance"
  name        = "database-${var.stack_name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  tags = merge(
    var.tags,
    {
      Name = "database-${var.stack_name}"
    }
  )
}

resource "aws_security_group_rule" "weblogic_server" {
  description       = "DB access from weblogic (private subnet)"
  type              = "ingress"
  security_group_id = aws_security_group.database_server.id
  from_port         = "1521"
  to_port           = "1521"
  protocol          = "TCP"
  cidr_blocks       = ["${aws_instance.weblogic_server.private_ip}/32"]
  depends_on        = [aws_instance.weblogic_server]
}

# locals {database_extra_ingress_rules = jsondecode(var.database_extra_ingress_rules)}

resource "aws_security_group_rule" "extra_rules" { # Extra ingress rules that might be specified
  for_each          = { for rule in try(var.database_extra_ingress_rules) : "${rule.description}-${rule.type}" => rule }
  type              = "ingress"
  security_group_id = aws_security_group.database_server.id
  description       = lookup(each.value, "description")
  from_port         = lookup(each.value, "from_port")
  to_port           = lookup(each.value, "to_port")
  cidr_blocks       = lookup(each.value, "cidr_blocks")
  protocol          = lookup(each.value, "protocol")
}

#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------
data "aws_ami" "database_image" {
  most_recent = true
  owners      = [var.database_ami_owner]

  filter {
    name   = "name"
    values = [var.database_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  database_root_device_size = one([for bdm in data.aws_ami.database_image.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.database_image.root_device_name])
}

# user-data template
data "template_file" "database_init" {
  template = file("${path.module}/user_data/database_init.sh")
  vars = {
    parameter_name_ASMSYS  = aws_ssm_parameter.asm_sys.name
    parameter_name_ASMSNMP = aws_ssm_parameter.asm_snmp.name
  }
}

resource "aws_instance" "database_server" {
  ami                         = data.aws_ami.database_image.id
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = var.instance_profile_name
  instance_type               = var.database_instance_type # tflint-ignore: aws_instance_invalid_type
  key_name                    = var.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_az_a.id
  user_data                   = base64encode(data.template_file.database_init.rendered)
  vpc_security_group_ids = [
    var.database_common_security_group_id,
    aws_security_group.database_server.id
  ]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = lookup(var.database_drive_map, data.aws_ami.database_image.root_device_name, local.database_root_device_size)
    volume_type           = "gp3"
  }
  dynamic "ephemeral_block_device" { # block devices specified inline cannot be resized later so we need to make sure they are not mounted here
    for_each = [for bdm in data.aws_ami.database_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.database_image.root_device_name]
    iterator = device
    content {
      device_name = device.value.device_name
      no_device   = true
    }
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device, # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    var.tags,
    {
      Name       = "database-${var.stack_name}"
      component  = "data"
      os_type    = "Linux"
      os_version = "RHEL 7.9"
      always_on  = "false"
    }
  )
}

resource "aws_ebs_volume" "database_server_ami_volume" {
  for_each = { for bdm in data.aws_ami.database_image.block_device_mappings : bdm.device_name => bdm if bdm.device_name != data.aws_ami.database_image.root_device_name }

  availability_zone = "${var.region}a"
  encrypted         = true
  iops              = each.value["ebs"]["iops"]
  snapshot_id       = each.value["ebs"]["snapshot_id"]
  size              = lookup(var.database_drive_map, each.value["device_name"], each.value["ebs"]["volume_size"])
  type              = each.value["ebs"]["volume_type"]

  tags = merge(
    var.tags,
    {
      Name = "database-${var.stack_name}-${each.value.device_name}"
    }
  )
}

resource "aws_volume_attachment" "database_server_ami_volume" {
  for_each = aws_ebs_volume.database_server_ami_volume

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database_server.id
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

resource "aws_route53_record" "database_internal" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "db.${var.stack_name}.${var.application_name}.${data.aws_route53_zone.internal.name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.database_server.private_ip]
}

resource "aws_route53_record" "database_external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "db.${var.stack_name}.${var.application_name}.${data.aws_route53_zone.external.name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.database_server.private_ip]
}

#------------------------------------------------------------------------------
# ASM Passwords
#------------------------------------------------------------------------------

resource "random_password" "asm_sys" {

  length  = 30
  special = false
}

resource "aws_ssm_parameter" "asm_sys" {
  name        = "/database/${var.stack_name}/ASMSYS"
  description = "${var.stack_name} ASMSYS password"
  type        = "SecureString"
  value       = random_password.asm_sys.result

  tags = merge(
    var.tags,
    {
      Name = "database-${var.stack_name}-ASMSYS"
    }
  )
}

resource "random_password" "asm_snmp" {

  length  = 30
  special = false
}

resource "aws_ssm_parameter" "asm_snmp" {
  name        = "/database/${var.stack_name}/ASMSNMP"
  description = "ASMSNMP password ${var.stack_name}"
  type        = "SecureString"
  value       = random_password.asm_snmp.result

  tags = merge(
    var.tags,
    {
      Name = "database-${var.stack_name}-ASMSNMP"
    }
  )
}

#------------------------------------------------------------------------------
# Instance IAM role extra permissions
# Temporarily allow get parameter when instance first created
# Attach policy inline on ec2-common-role
#------------------------------------------------------------------------------

resource "time_offset" "asm_parameter" {
  # static time resource for controlling access to parameter
  offset_minutes = 30
  triggers = {
    # if the instance is recycled we reset the timestamp to give access again
    instance_id = aws_instance.database_server.arn
  }
}

data "aws_iam_policy_document" "asm_parameter" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter*"]
    resources = ["arn:aws:ssm:${var.region}:*:parameter/database/${var.stack_name}/*"]
    condition {
      test     = "DateLessThan"
      variable = "aws:CurrentTime"
      values   = [time_offset.asm_parameter.rfc3339]
    }
    condition {
      test     = "StringLike"
      variable = "ec2:SourceInstanceARN"
      values   = [aws_instance.database_server.arn]
    }
  }
}

data "aws_iam_instance_profile" "ec2_common_profile" {
  name = var.instance_profile_name
}

resource "aws_iam_role_policy" "asm_parameter" {
  name   = "asm-parameter-access-${var.stack_name}"
  role   = data.aws_iam_instance_profile.ec2_common_profile.role_name
  policy = data.aws_iam_policy_document.asm_parameter.json
}
