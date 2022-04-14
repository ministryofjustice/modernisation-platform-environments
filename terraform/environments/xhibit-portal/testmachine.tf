resource "aws_security_group" "testmachine" {
  description = "Configure testmachine access - ingress should be only from Bastion"
  name        = "testmachine-${local.application_name}"
  vpc_id      = local.vpc_id

}

resource "aws_instance" "testmachine" {

  depends_on             = [aws_security_group.testmachine]
  instance_type          = "t3a.large"
  ami                    = local.application_data.accounts[local.environment].importmachine-ami
  vpc_security_group_ids = [aws_security_group.testmachine.id]
  monitoring             = true
  ebs_optimized          = true
  subnet_id              = data.aws_subnet.private_az_a.id
  key_name               = aws_key_pair.george.key_name

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
    
    prevent_destroy = environment == "production" ? true : false
  }

  tags = merge(
    local.tags,
    {
      Name = "testmachine-${local.application_name}"
    }
  )
}