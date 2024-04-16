resource "aws_instance" "delete-account_test_instance" {
  ami                         = local.application_data.accounts[local.environment].ec2amiid
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  instance_type               = local.application_data.accounts[local.environment].ec2instancetype
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id


  root_block_device {
    delete_on_termination = false
    encrypted             = true
    volume_size           = 60
    volume_type           = "gp2"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_name}test-ec2-root" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} test server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}