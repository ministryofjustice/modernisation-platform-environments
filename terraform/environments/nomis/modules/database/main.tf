#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

# get business unit vpc
data "aws_vpc" "shared_vpc" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

resource "aws_security_group" "database" {
  description = "Security group rules specific to this database instance"
  name        = "database-${var.name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  tags = merge(
    var.tags,
    {
      Name = "database-${var.name}",
  })
}

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
# EC2
#------------------------------------------------------------------------------

# user-data template
data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")
  vars = {
    parameter_name_ASMSYS  = aws_ssm_parameter.asm_sys.name
    parameter_name_ASMSNMP = aws_ssm_parameter.asm_snmp.name
    volume_ids             = join(" ", local.volume_ids)
    restored_from_snapshot = var.restored_from_snapshot
  }
}

# get data subnet for the AZ
data "aws_subnet" "data" {
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-${var.subnet_type}-${var.availability_zone}"
  }
}

data "aws_subnet" "private" {
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-private-${var.availability_zone}"
  }
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.database.id
  associate_public_ip_address = false
  disable_api_termination     = var.termination_protection
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.database.name
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data.id
  user_data                   = length(var.oracle_sids) == 0 ? base64encode(data.template_file.user_data.rendered) : data.cloudinit_config.oracle_monitoring_and_userdata.rendered
  vpc_security_group_ids = [
    var.common_security_group_id,
    aws_security_group.database.id
  ]
  #checkov:skip=CKV_AWS_79:We are tied to v1 metadata service
  metadata_options {
    http_endpoint = "enabled"
    #tfsec:ignore:aws-ec2-enforce-http-token-imds:the Oracle installer cannott accommodate a token
    http_tokens = "optional"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    # volume_size           = lookup(var.drive_map, data.aws_ami.database.root_device_name, local.root_device_size)
    volume_type = "gp3"

    tags = merge(
      var.tags,
      {
        Name = "database-${var.name}-root-${data.aws_ami.database.root_device_name}"
      }
    )
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
      user_data, # Prevent changes to user_data from destroying existing EC2s
    ]
  }

  tags = merge(
    var.tags,
    {
      Name          = "database-${var.name}"
      description   = var.description
      servername    = var.name
      component     = "data"
      os_type       = "Linux"
      os_version    = "RHEL 7.9"
      always_on     = var.always_on
      "Patch Group" = "RHEL"
    },
  [length(var.oracle_sids) > 0 ? { oracle_sids = try(join(",", var.oracle_sids), "") } : null]...)
}
#tfsec:ignore:aws-ebs-encryption-customer-key:exp:2022-08-31: I don't think we need the fine grained control CMK would provide
resource "aws_ebs_volume" "oracle_app" {
  for_each = toset(local.oracle_app_disks)

  availability_zone = var.availability_zone
  encrypted         = true
  snapshot_id       = local.block_device_map[each.key].ebs.snapshot_id
  size              = lookup(var.oracle_app_disk_size, each.key, local.block_device_map[each.key].ebs.volume_size)
  type              = "gp3"

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

#tfsec:ignore:aws-ebs-encryption-customer-key:exp:2022-08-31: I don't think we need the fine grained control CMK would provide
resource "aws_ebs_volume" "asm_data" {
  for_each = toset(local.asm_data_disks)

  availability_zone = var.availability_zone
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

  lifecycle {
    ignore_changes = [snapshot_id] # retain data if AMI is updated. If you want to start from fresh, destroy it
  }
}

resource "aws_volume_attachment" "asm_data" {
  for_each = aws_ebs_volume.asm_data

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database.id
}

#tfsec:ignore:aws-ebs-encryption-customer-key:exp:2022-08-31: I don't think we need the fine grained control CMK would provide
resource "aws_ebs_volume" "asm_flash" {
  for_each = toset(local.asm_flash_disks)

  availability_zone = var.availability_zone
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

  lifecycle {
    ignore_changes = [snapshot_id] # retain data if AMI is updated. If you want to start from fresh, destroy it
  }
}

resource "aws_volume_attachment" "asm_flash" {
  for_each = aws_ebs_volume.asm_flash

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database.id
}

#tfsec:ignore:aws-ebs-encryption-customer-key:exp:2022-08-31: I don't think we need the fine grained control CMK would provide
resource "aws_ebs_volume" "swap" {
  availability_zone = var.availability_zone
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

locals {
  volume_ids = concat(
    [for k, v in aws_ebs_volume.asm_data : v.id],
    [for k, v in aws_ebs_volume.asm_flash : v.id],
    [for k, v in aws_ebs_volume.oracle_app : v.id],
    [aws_ebs_volume.swap.id]
  )
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.internal."
  private_zone = true
}

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

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
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    #tfsec:ignore:aws-iam-no-policy-wildcards: acccess scoped to parameter path, plus time conditional restricts access to short duration after launch
    resources = ["arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.id}:parameter/database/${var.name}/*"]
    condition {
      test     = "DateLessThan"
      variable = "aws:CurrentTime"
      values   = [time_offset.asm_parameter.rfc3339]
    }
  }
}
resource "aws_iam_role" "database" {
  name                 = "ec2-database-role-${var.name}"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )

  managed_policy_arns = var.instance_profile_policies

  tags = merge(
    var.tags,
    {
      Name = "ec2-database-role-${var.name}"
    },
  )
}

resource "aws_iam_role_policy" "asm_parameter" {
  name   = "asm-parameter-access-${var.name}"
  role   = aws_iam_role.database.id
  policy = data.aws_iam_policy_document.asm_parameter.json
}

resource "aws_iam_instance_profile" "database" {
  name = "ec2-database-profile-${var.name}"
  role = aws_iam_role.database.name
  path = "/"
}

# Resources for Oracle DB monitoring

data "cloudinit_config" "oracle_monitoring_and_userdata" {
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data.rendered
  }
  dynamic "part" {
    for_each = var.oracle_sids[*]
    content {
      content_type = "text/cloud-config"
      merge_type   = "list(append)+dict(recurse_list)+str(append)"
      content = yamlencode({
        write_files = [
          {
            encoding    = "b64"
            content     = base64encode(templatefile("${path.module}/templates/oracle-health.sh.tftpl", { oracle_sid = part.value }))
            path        = "/home/oracle/oracle-health-${part.value}.sh"
            owner       = "oracle:oinstall"
            permissions = "0500"
          },
        ]
      })

    }
  }

  dynamic "part" {
    for_each = try(slice(var.oracle_sids, 0, 1), [])
    content {
      content_type = "text/cloud-config"
      merge_type   = "list(append)+dict(recurse_list)+str(append)"
      content = yamlencode({
        write_files = [
          {
            encoding    = "b64"
            content     = base64encode(templatefile("${path.module}/templates/config.yml.tftpl", { oracle_sids = var.oracle_sids }))
            path        = "/home/oracle/config.yml"
            owner       = "root:root"
            permissions = "0755"
          },
        ]
      })

    }
  }

}
