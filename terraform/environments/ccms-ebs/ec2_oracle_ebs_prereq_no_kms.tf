#  Build EC2 
resource "aws_instance" "ec2_oracle_base_ebs_cmk" {
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebs_cmk
  ami                         = data.aws_ami.oracle_base_ready.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_oracle_base.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oracle_base.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below
  lifecycle {
    ignore_changes = [ebs_block_device]
  }

  user_data = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
sudo systemctl stop amazon-ssm-agent
sudo rm -rf /var/lib/amazon/ssm/ipc/
sudo systemctl start amazon-ssm-agent
sudo mount -a

EOF


  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = false
    kms_key_id  = aws_kms_key.oracle_ec2.arn
    tags = merge(local.tags,
      { Name = "root-block" }
    )
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 200
    encrypted   = false
    kms_key_id  = aws_kms_key.oracle_ec2.arn
    tags = merge(local.tags,
      { Name = "ebs-block1" }
    )
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-Oracle-EBS-base", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.ec2_sg_oracle_base]
}
