#------------------------------------------------------------------------------
# EC2
#------------------------------------------------------------------------------

resource "aws_instance" "this" {
  ami                         = data.aws_ami.this.id
  associate_public_ip_address = false
  disable_api_termination     = var.instance.disable_api_termination
  ebs_optimized               = data.aws_ec2_instance_type.this.ebs_optimized_support == "unsupported" ? false : true
  iam_instance_profile        = aws_iam_instance_profile.this.name
  instance_type               = var.instance.instance_type
  key_name                    = var.instance.key_name
  monitoring                  = coalesce(var.instance.monitoring, true)
  subnet_id                   = data.aws_subnet.this.id
  user_data                   = length(data.cloudinit_config.this) == 0 ? local.user_data_raw : data.cloudinit_config.this[0].rendered
  vpc_security_group_ids      = var.instance.vpc_security_group_ids

  metadata_options {
    #checkov:skip=CKV_AWS_79:This isn't enabled in every environment, so we can't enforce it
    #tfsec:ignore:aws-ec2-enforce-http-token-imds
    http_endpoint = coalesce(var.instance.metadata_endpoint_enabled, "disabled")
    http_tokens   = coalesce(var.instance.metadata_options_http_tokens, "required")
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = try(var.instance.root_block_device.volume_size, local.ami_block_device_mappings_root.ebs.volume_size)
    volume_type           = local.ami_block_device_mappings_root.ebs.volume_type

    tags = merge(local.tags, {
      Name = join("-", [var.name, "root", local.ami_block_device_mappings_root.device_name])
    })
  }

  # block devices specified inline cannot be resized later so remove them here
  # and define as ebs_volumes later
  dynamic "ephemeral_block_device" {
    for_each = local.ami_block_device_mappings_nonroot
    content {
      device_name = ephemeral_block_device.value.device_name
      no_device   = true
    }
  }

  dynamic "private_dns_name_options" {
    for_each = var.instance.private_dns_name_options != null ? [var.instance.private_dns_name_options] : []
    content {
      enable_resource_name_dns_aaaa_record = private_dns_name_options.value.enable_resource_name_dns_aaaa_record
      enable_resource_name_dns_a_record    = private_dns_name_options.value.enable_resource_name_dns_a_record
      hostname_type                        = private_dns_name_options.value.hostname_type
    }
  }

  lifecycle {
    ignore_changes = [
      user_data, # Prevent changes to user_data from destroying existing EC2s
    ]
  }

  tags = merge(local.tags, {
    Name = var.name
  })
}

#------------------------------------------------------------------------------
# DISKS
#------------------------------------------------------------------------------

#tfsec:ignore:aws-ebs-encryption-customer-key:exp:2022-10-31: I don't think we need the fine grained control CMK would provide
#checkov:skip=CKV_AWS_189:I don't think we need the fine grained control CMK would provide
resource "aws_ebs_volume" "this" {
  for_each = local.ebs_volumes

  # Values are retrieved from AMI data rather than using snapshot_id, since 
  # it's not always possible to access the snapshot_id if the AMI is in a 
  # different account.
  availability_zone = var.availability_zone
  encrypted         = true
  iops              = try(each.value.iops > 0, false) ? each.value.iops : null
  throughput        = try(each.value.throughput > 0, false) ? each.value.throughput : null
  size              = each.value.size
  type              = each.value.type

  tags = merge(
    local.tags,
    {
      Name = try(
        join("-", [var.name, each.value.label, each.key]),
        join("-", [var.name, each.key])
      )
    }
  )

  lifecycle {
    ignore_changes = [snapshot_id] # retain data if AMI is updated. If you want to start from fresh, destroy it
  }
}

resource "aws_volume_attachment" "this" {
  for_each = aws_ebs_volume.this

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.this.id
}

#------------------------------------------------------------------------------
# Route 53 record
#------------------------------------------------------------------------------

resource "aws_route53_record" "internal" {
  count    = var.route53_records.create_internal_record ? 1 : 0
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "${var.name}.${var.application_name}.${data.aws_route53_zone.internal.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.this.private_ip]
}

resource "aws_route53_record" "external" {
  count    = var.route53_records.create_external_record ? 1 : 0
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.name}.${var.application_name}.${data.aws_route53_zone.external.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.this.private_ip]
}

#------------------------------------------------------------------------------
# ASM Passwords
#------------------------------------------------------------------------------

resource "random_password" "this" {
  for_each = var.ssm_parameters != null ? var.ssm_parameters : {}

  length  = each.value.random.length
  special = lookup(each.value.random, "special", null)
}

resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_parameters != null ? var.ssm_parameters : {}

  name        = "/${var.ssm_parameters_prefix}${var.name}/${each.key}"
  description = each.value.description
  type        = "SecureString"
  value       = random_password.this[each.key].result

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-${each.key}"
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
    instance_id = aws_instance.this.arn
  }
}

data "aws_iam_policy_document" "asm_parameter" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    #tfsec:ignore:aws-iam-no-policy-wildcards: acccess scoped to parameter path, plus time conditional restricts access to short duration after launch
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.id}:parameter/${var.ssm_parameters_prefix}${var.name}/*"]
    condition {
      test     = "DateLessThan"
      variable = "aws:CurrentTime"
      values   = [time_offset.asm_parameter.rfc3339]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "${var.iam_resource_names_prefix}-role-${var.name}"
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
    local.tags,
    {
      Name = "${var.iam_resource_names_prefix}-role-${var.name}"
    },
  )
}

resource "aws_iam_role_policy" "asm_parameter" {
  count  = var.ssm_parameters != null ? 1 : 0
  name   = "asm-parameter-access-${var.name}"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.asm_parameter.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.iam_resource_names_prefix}-profile-${var.name}"
  role = aws_iam_role.this.name
  path = "/"
}
