

# Security Groups
resource "aws_security_group" "app-server" {
  description = "Domain traffic only"
  name        = "app-server-${local.application_name}"
  vpc_id      = local.vpc_id

  egress {
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "SSH from Bastion"
    from_port   = 0
    to_port     = "3389"
    protocol    = "TCP"
    cidr_blocks = ["${module.bastion_linux.bastion_private_ip}/32"]
  }


}


resource "aws_instance" "app-server" {
  instance_type               = "t2.medium"
  ami                         = local.application_data.accounts[local.environment].app-ami
  vpc_security_group_ids      = [aws_security_group.app-server.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.george.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "app-${local.application_name}"
    }
  )
}
