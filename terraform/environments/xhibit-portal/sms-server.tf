resource "aws_instance" "sms-server" {
  # checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized"
  depends_on                  = [aws_security_group.sms_server]
  instance_type               = "t3.large"
  ami                         = local.application_data.accounts[local.environment].XHBPRESMS01-ami
  vpc_security_group_ids      = [aws_security_group.sms_server.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.gary.key_name
  #key_name                    = aws_key_pair.george.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_xp_profile.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
    tags = {
      Name = "root-block-device-sms-server-${local.application_name}"
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
      #root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]

    prevent_destroy = false
  }

  tags = merge(
    local.tags,
    {
      Name = "sms-${local.application_name}"
    }
  )
}
