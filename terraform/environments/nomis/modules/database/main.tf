#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------

locals {
  oracle_app_disks = [ # match structure of AMI block device mappings
    "/dev/sdb",
    "/dev/sdc"
  ]
  asm_data_disks = [ # match structure of AMI block device mappings
    "/dev/sde",      # DATA01
    "/dev/sdf",      # DATA02
    "/dev/sdg",      # DATA03
    "/dev/sdh",      # DATA04
    "/dev/sdi",      # DATA05
  ]
  asm_flash_disks = [ # match structure of AMI block device mappings
    "/dev/sdj",       # FLASH01
    "/dev/sdk"        # FLASH02
  ]
  swap_disk = "/dev/sds" # match structure of AMI block device mappings

  asm_data_disk_size  = floor(var.asm_data_capacity / length(local.asm_data_disks))
  asm_flash_disk_size = floor(var.asm_flash_capacity / length(local.asm_flash_disks))
  block_device_map    = { for bdm in data.aws_ami.database.block_device_mappings : bdm.device_name => bdm }
  root_device_size    = one([for bdm in data.aws_ami.database.block_device_mappings : bdm.ebs.volume_size if bdm.device_name == data.aws_ami.database.root_device_name])
}

#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "database" {
  description = "Stack specific security group rules for database instance"
  name        = "database-${var.name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}"
    }
  )
}

# resource "aws_security_group_rule" "weblogic" {
#   description       = "DB access from weblogic (private subnet)"
#   type              = "ingress"
#   security_group_id = aws_security_group.database.id
#   from_port         = "1521"
#   to_port           = "1521"
#   protocol          = "TCP"
#   cidr_blocks       = ["${aws_instance.weblogic_server.private_ip}/32"]
# }

resource "aws_security_group_rule" "extra_rules" { # Extra ingress rules that might be specified
  for_each          = { for rule in var.extra_ingress_rules : "${rule.description}-${rule.to_port}" => rule }
  type              = "ingress"
  security_group_id = aws_security_group.database.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
  protocol          = each.value.protocol
}
#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------

data "aws_ami" "database" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# user-data template
data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")
  vars = {
    parameter_name_ASMSYS  = aws_ssm_parameter.asm_sys.name
    parameter_name_ASMSNMP = aws_ssm_parameter.asm_snmp.name
  }
}

data "aws_ec2_instance_type" "database" {
  instance_type = var.instance_type
}

locals {
  # set swap space according to https://docs.oracle.com/cd/E11882_01/install.112/e47689/oraclerestart.htm#LADBI1214 (assuming we will never have instances < 2GB)
  # output from datasource is in MiB, we spec swap sapce in GiB
  swap_disk_size = data.aws_ec2_instance_type.database.memory_size >= 16384 ? 16 : (data.aws_ec2_instance_type.database.memory_size / 1024)
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.database.id
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = var.instance_profile_name
  instance_type               = var.instance_type # tflint-ignore: aws_instance_invalid_type
  key_name                    = var.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_az_a.id
  user_data                   = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [
    var.common_security_group_id,
    aws_security_group.database.id
  ]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    # volume_size           = lookup(var.drive_map, data.aws_ami.database.root_device_name, local.root_device_size)
    volume_type = "gp3"
  }
  dynamic "ephemeral_block_device" { # block devices specified inline cannot be resized later so we need to make sure they are not mounted here
    for_each = [for bdm in data.aws_ami.database.block_device_mappings : bdm if bdm.device_name != data.aws_ami.database.root_device_name]
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
      Name       = "database-${var.name}"
      component  = "data"
      os_type    = "Linux"
      os_version = "RHEL 7.9"
      always_on  = var.environment == "test" ? "false" : "true"
    }
  )
}

resource "aws_ebs_volume" "oracle_app" {
  for_each = toset(local.oracle_app_disks)

  availability_zone = "${var.region}a"
  encrypted         = true
  # iops              = var.oracle_app_iops
  snapshot_id = local.block_device_map[each.key].ebs.snapshot_id
  # size              = local.oracle_app_disk_size
  # throughput = var.oracle_app_throughput
  type = "gp3"

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}-app-${each.key}"
    }
  )
}

resource "aws_volume_attachment" "oracle_app" {
  for_each = aws_ebs_volume.oracle_app

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "asm_data" {
  for_each = toset(local.asm_data_disks)

  availability_zone = "${var.region}a"
  encrypted         = true
  iops              = var.asm_data_iops
  snapshot_id       = local.block_device_map[each.key].ebs.snapshot_id
  size              = local.asm_data_disk_size
  throughput        = var.asm_data_throughput
  type              = "gp3"

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}-DATA-${each.key}"
    }
  )
}

resource "aws_volume_attachment" "asm_data" {
  for_each = aws_ebs_volume.asm_data

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "asm_flash" {
  for_each = toset(local.asm_flash_disks)

  availability_zone = "${var.region}a"
  encrypted         = true
  iops              = var.asm_flash_iops
  snapshot_id       = local.block_device_map[each.key].ebs.snapshot_id
  size              = local.asm_flash_disk_size
  throughput        = var.asm_flash_throughput
  type              = "gp3"

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}-FLASH-${each.key}"
    }
  )
}

resource "aws_volume_attachment" "asm_flash" {
  for_each = aws_ebs_volume.asm_flash

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database.id
}

resource "aws_ebs_volume" "swap" {
  availability_zone = "${var.region}a"
  encrypted         = true
  snapshot_id       = local.block_device_map[local.swap_disk].ebs.snapshot_id
  size              = local.swap_disk_size
  type              = "gp3"

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}-swap-${local.swap_disk}"
    }
  )
}

resource "aws_volume_attachment" "swap" {
  device_name = local.swap_disk
  volume_id   = aws_ebs_volume.swap.id
  instance_id = aws_instance.database.id
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

resource "aws_route53_record" "internal" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "db.${var.name}.${var.application_name}.${data.aws_route53_zone.internal.name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.database.private_ip]
}

resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "db.${var.name}.${var.application_name}.${data.aws_route53_zone.external.name}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.database.private_ip]
}

#------------------------------------------------------------------------------
# ASM Passwords
#------------------------------------------------------------------------------

resource "random_password" "asm_sys" {

  length  = 30
  special = false
}

resource "aws_ssm_parameter" "asm_sys" {
  name        = "/database/${var.name}/ASMSYS"
  description = "${var.name} ASMSYS password"
  type        = "SecureString"
  value       = random_password.asm_sys.result

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}-ASMSYS"
    }
  )
}

resource "random_password" "asm_snmp" {

  length  = 30
  special = false
}

resource "aws_ssm_parameter" "asm_snmp" {
  name        = "/database/${var.name}/ASMSNMP"
  description = "ASMSNMP password ${var.name}"
  type        = "SecureString"
  value       = random_password.asm_snmp.result

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}-ASMSNMP"
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
    instance_id = aws_instance.database.arn
  }
}

data "aws_iam_policy_document" "asm_parameter" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.id}:parameter/database/${var.name}/*"]
    condition {
      test     = "DateLessThan"
      variable = "aws:CurrentTime"
      values   = [time_offset.asm_parameter.rfc3339]
    }
    condition {
      test     = "StringLike"
      variable = "ec2:SourceInstanceARN"
      values   = [aws_instance.database.arn]
    }
  }
}

data "aws_iam_instance_profile" "database" {
  name = var.instance_profile_name
}

resource "aws_iam_role_policy" "asm_parameter" {
  name   = "asm-parameter-access-${var.name}"
  role   = data.aws_iam_instance_profile.database.role_name
  policy = data.aws_iam_policy_document.asm_parameter.json
}
