#------------------------------------------------------------------------------
# AMI and EC2
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# user-data template
data "template_file" "database_init" {
  template = file("${path.module}/templates/database_init.sh")
  vars = {
    asm_disks = join("|", local.asm_disks)
    parameter_name_ASMSYS  = aws_ssm_parameter.asm_sys.name
    parameter_name_ASMSNMP = aws_ssm_parameter.asm_snmp.name
  }
}

resource "aws_instance" "database_server" {
  ami                         = "ami-0512c9e41b715b2ca"
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_database_profile.name
  instance_type               = "t3.medium" # tflint-ignore: aws_instance_invalid_type
  key_name                    = aws_key_pair.ec2-user.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_az_a.id 
  user_data                   = base64encode(data.template_file.database_init.rendered)
  vpc_security_group_ids = [aws_security_group.database_common.id]
 
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 30
    volume_type           = "gp3"
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
    local.tags,
    {
      Name       = "database-test"
      component  = "data"
      os_type    = "Linux"
      os_version = "RHEL 7.9"
      always_on  = "false"
    }
  )
}

# Attach any asm ebs volumes, not in the AMI block device map, but specified in var.database_drive_map
locals{
  database_asm_disks = [
    {
      device_name = "/dev/sde"
      size = 100
      type = "gp3"
    },
    {
      device_name = "/dev/sdf"
      size = 100
      type = "gp3"
    }
  ]
}

resource "aws_ebs_volume" "database_server_asm_volume" {
  for_each = { for disk in local.database_asm_disks : disk.device_name => disk }

  availability_zone = "${local.region}a"
  encrypted         = true
  size              = each.value.size
  type              = each.value.type

  tags = merge(
    local.tags,
    {
      Name = "database-test-${each.value.device_name}"
    }
  )
}

resource "aws_volume_attachment" "database_server_asm_volume" {
  for_each = aws_ebs_volume.database_server_asm_volume

  device_name = each.key
  volume_id   = each.value.id
  instance_id = aws_instance.database_server.id
}

locals {
  # create pipe separated values for passing to bash script.  Also trim the volume id prefix as it is formated slightly different on the VM
  # asm_disks = [ for k, v in aws_ebs_volume.database_server_asm_volume : join("|", [v.label, trimprefix(v.id, "vol-")]) ]
  asm_disks = [ for k, v in aws_ebs_volume.database_server_asm_volume : trimprefix(v.id, "vol-") ]
}


#------------------------------------------------------------------------------
# ASM Passwords
#------------------------------------------------------------------------------

resource "random_password" "asm_sys" {

  length  = 30
  special = false
}

resource "aws_ssm_parameter" "asm_sys" {
  name        = "/database/test/ASMSYS"
  description = "test ASMSYS password"
  type        = "SecureString"
  value       = random_password.asm_sys.result

  tags = merge(
    local.tags,
    {
      Name = "database-test-ASMSYS"
    }
  )
}

resource "random_password" "asm_snmp" {

  length  = 30
  special = false
}

resource "aws_ssm_parameter" "asm_snmp" {
  name        = "/database/test/ASMSNMP"
  description = "ASMSNMP password test"
  type        = "SecureString"
  value       = random_password.asm_snmp.result

  tags = merge(
    local.tags,
    {
      Name = "database-test-ASMSNMP"
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
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.id}:parameter/database/test/*"]
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

resource "aws_iam_role_policy" "asm_parameter" {
  name   = "asm-parameter-access-test"
  role   = aws_iam_role.ec2_database_role.name
  policy = data.aws_iam_policy_document.asm_parameter.json
}