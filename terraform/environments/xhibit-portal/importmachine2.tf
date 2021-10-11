# get shared subnet-set private (az (a) subnet)
data "aws_subnet" "private_az_a" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

##### EC2 ####
data "aws_ami" "win2003" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "win2003" {
  instance_type               = "t4g.large"
  ami                         = data.aws_ami.win2003.id
  monitoring                  = true
  associate_public_ip_address = false
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id

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
      Name = "win2003-${local.application_name}"
    }
  )
}

resource "aws_ebs_volume" "disk_xvdf" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 400

  tags = merge(
    local.tags,
    {
      Name = "win2003-${local.application_name}-disk"
    }
  )
}

resource "aws_volume_attachment" "disk_xvdf" {
  device_name = "xvdf"
  volume_id   = aws_ebs_volume.disk_xvdf.id
  instance_id = aws_instance.win2003.id
} 