# Temporary linux server to change the windows admin account passwords that have expired.

resource "aws_key_pair" "ben" {
  key_name   = "ben_terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLeNgZXoOyElltYhtuAbiYmU8QqsNhdPVeuDs+cVof52MtSzlRMStbfLVuui8hM9/lleUOqYW1vdQKZu2fHPuAxUTJNzN0yqKaqpSqsbnbEmUKJpMt5OGDOx6NZR6kTOoROn65p/Va8vrZ5aT5cnWNP2g54gE2Jt244OsFl4dQAtgxX+A3EB0iVbr6VS+MJ4U6zynH+xUvrYsASn9fj3HBInHFWj6g89o/JQRXwOfxeK67UKNYYP76quxPPqiabIeC+Z9eiieveSx7Y/Onjlo3tYz1LaNyiXmAPSuAvPBG0B5oftAi46VUvL6ts9s0Ifz6WvAQwbXpH7MUr6ELkGWrTeltiYmdNZweJ97y9ci4eeH3LdN2haj1D0ApSnn1/RCU9owz7cey2roqBy8pWjB0dUoyfwa0CTOYDiglB2xVuP+na/GSizlpnwOtC5HqcdHQHx5O9NZT1MqExUsQ7U5lAonjDpvwXt+Xd1AR+QAE69j1r2u/QJ/CezrIkVFqroE= ben.moore@L1451"
}

resource "aws_instance" "sms-recovery-server" {
  depends_on                  = [aws_security_group.sms_server]
  instance_type               = "t2.micro"
  ami                         = local.application_data.accounts[local.environment].sms-recovery-ami
  vpc_security_group_ids      = [aws_security_group.sms_server.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.ben.key_name

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
      #root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
    
    prevent_destroy = false
  }

  tags = merge(
    local.tags,
    {
      Name = "sms-recovery-${local.application_name}"
    }
  )
}
