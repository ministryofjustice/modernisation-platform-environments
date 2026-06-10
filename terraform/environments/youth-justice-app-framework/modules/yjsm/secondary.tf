resource "aws_network_interface" "build" {
  count           = var.create_secondary ? 1 : 0
  subnet_id       = var.subnet_id
  private_ips     = var.private_ip_build != null ? [var.private_ip_build] : []
  security_groups = [aws_security_group.yjsm_service.id]
}

resource "aws_instance" "yjsm_build" {
  count                       = var.create_secondary ? 1 : 0
  ami                         = ami-078b41f5b9f1cd570
  instance_type               = "t3a.xlarge"
  key_name                    = module.key_pair.key_pair_name
  monitoring                  = true
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.yjsm_ec2_profile.id
  user_data                   = data.template_file.userdata.rendered
  user_data_replace_on_change = true

  tags = merge(
    local.all_tags,
    { "Name" = "YJSM-al23-build", "OS" = "Linux", "Purpose" = "AMI-Build" }
  )

  network_interface {
    network_interface_id = aws_network_interface.build[0].id
    device_index         = 0
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = false
    volume_size           = 80
    volume_type           = "gp2"
  }
}

variable "create_secondary" {
  description = "Whether to create a secondary instance for AMI building"
  type        = bool
  default     = false
}

variable "private_ip_build" {
  description = "Private IP for the temporary build instance"
  type        = string
  default     = null
}