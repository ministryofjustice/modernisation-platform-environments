######################################
### SSH KEY PAIR GENERATION
######################################
resource "tls_private_key" "ec2_ssh_key" {
  count     = contains(["test", "preproduction"], local.environment) ? 1 : 0
  algorithm = "ED25519"
}

resource "aws_key_pair" "ec2_key_pair" {
  count      = contains(["test", "preproduction"], local.environment) ? 1 : 0
  key_name   = "${local.application_name}-${local.environment}-key"
  public_key = tls_private_key.ec2_ssh_key[0].public_key_openssh

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-key" }
  )
}

resource "aws_secretsmanager_secret" "ec2_ssh_private_key" {
  count       = contains(["test", "preproduction"], local.environment) ? 1 : 0
  name        = "${local.application_name}-${local.environment}/ec2-ssh-private-key"
  description = "Private SSH key for ${local.application_name} EC2 instance"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ssh-private-key" }
  )
}

resource "aws_secretsmanager_secret_version" "ec2_ssh_private_key_version" {
  count     = contains(["test", "preproduction"], local.environment) ? 1 : 0
  secret_id = aws_secretsmanager_secret.ec2_ssh_private_key[0].id
  secret_string = jsonencode({
    private_key = tls_private_key.ec2_ssh_key[0].private_key_openssh
    public_key  = tls_private_key.ec2_ssh_key[0].public_key_openssh
  })
}

######################################
### EC2 INSTANCE Userdata File
######################################
locals {
  userdata_new = replace(
    file("${path.module}/files/new-userdata.sh"),
    "$${dns_zone_name}",
    data.aws_route53_zone.external.name
  )
}

######################################
### EC2 Network Interface (ENI)
######################################
resource "aws_network_interface" "oas_eni_new" {
  count     = contains(["test", "preproduction"], local.environment) ? 1 : 0
  subnet_id       = data.aws_subnet.private_subnets_a.id
  private_ips     = [local.application_data.accounts[local.environment].ec2_private_ip]
  security_groups = [aws_security_group.ec2_sg[0].id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-eni" }
  )
}

######################################
### EC2 INSTANCE
######################################
resource "aws_instance" "oas_app_instance_new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  ami                         = local.application_data.accounts[local.environment].ec2amiid
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  key_name                    = aws_key_pair.ec2_key_pair[0].key_name
  monitoring                  = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile_new[0].id
  user_data_replace_on_change = true
  user_data                   = base64encode(local.userdata_new)

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.oas_eni_new[0].id
  }

  depends_on = [
    aws_volume_attachment.oas_EC2ServerVolume01_new,
    aws_volume_attachment.oas_EC2ServerVolume02_new
  ]

  root_block_device {
    delete_on_termination = false
    encrypted             = true 
    volume_size           = 40
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}-root-volume" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} Apps Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}

