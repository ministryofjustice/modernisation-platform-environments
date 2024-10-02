data "local_file" "userdata" {
  filename = "./files/userdata.sh"
}

######################################
# CIS EC2 Instance
######################################

resource "aws_instance" "cis_db_instance" {
  ami                    = local.application_data.accounts[local.environment].app_ami_id
  instance_type          = local.application_data.accounts[local.environment].ec2instancetype
  key_name               = aws_key_pair.cis.key_name
  ebs_optimized          = true
  subnet_id              = data.aws_subnet.data_subnets_a.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_instance_sg.id]
  user_data_replace_on_change = true
  user_data                   = base64encode(data.local_file.userdata.content)
  
  root_block_device {
    delete_on_termination = false
    encrypted             = true 
    volume_size           = 200
    volume_type           = "gp2"
    tags = merge(
      { "instance-scheduling" = "skip-scheduling" },
      local.tags,
      { "Name" = "${local.application_name_short}-cis-root" }
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} DB Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}


######################################
# CIS IAM Role
######################################

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.application_name_short}-ec2-profile"
  role = aws_iam_role.cis_ec2_role.name
}


######################################
# CIS EC2 EBS Volumes
######################################

resource "aws_ebs_volume" "EC2ServerVolumeORAHOME" {
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].orahomesize
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  snapshot_id       = local.application_data.accounts[local.environment].orahome_snapshot

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-EC2ServerVolumeORAHOME" },
  )
}

resource "aws_volume_attachment" "oas_EC2ServerVolume01" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.EC2ServerVolumeORAHOME.id
  instance_id = aws_instance.oas_app_instance.id
}

######################################
# CIS EC2 Security Group
######################################

resource "aws_security_group" "ec2_instance_sg" {
  name        = "${local.application_name_short}-${local.environment}-app-security-group"
  description = "Security Group for EC2 DB instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short}-${local.environment}-app-security-group" }
  )
}

resource "aws_vpc_security_group_egress_rule" "app_outbound" {
  security_group_id = aws_security_group.ec2_instance_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "app_bastion_ssh" {
  security_group_id            = aws_security_group.ec2_instance_sg.id
  description                  = "SSH from the Bastion"
  referenced_security_group_id = module.bastion_linux.bastion_security_group
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "rds_workspaces" {
  security_group_id = aws_security_group.ec2_instance_sg.id
  description       = "RDS Workspace access"
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
  cidr_ipv4         = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_vpc_security_group_ingress_rule" "dkron_workspaces" {
  security_group_id = aws_security_group.ec2_instance_sg.id
  description       = "Dkron Workspace access"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
  cidr_ipv4         = [local.application_data.accounts[local.environment].managementcidr]
}

resource "aws_vpc_security_group_ingress_rule" "rds_test_env" {
  security_group_id = aws_security_group.ec2_instance_sg.id
  description       = "RDS Workspace access"
  from_port         = 1521
  ip_protocol       = "tcp"
  to_port           = 1521
  cidr_ipv4         = [local.application_data.accounts[local.environment].testenvcidr]
}