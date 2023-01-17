data "aws_ami" "oracle_base" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# First build the security group for the EC2
resource "aws_security_group" "ec2_sg_oracle_base" {
  name        = "ec2_sg_oracle_base"
  description = "Baseline image of Oracle Linux 7.9"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-OracleBaseImage", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic_oracle_base" {
  for_each          = local.application_data.ec2_sg_ingress_rules_oracle_base_http
  security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type              = "ingress"
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = [data.aws_vpc.shared.cidr_block, "0.0.0.0/0"]
}
resource "aws_security_group_rule" "egress_traffic_oracle_base" {
  for_each          = local.application_data.ec2_sg_egress_rules_oracle_base
  security_group_id = aws_security_group.ec2_sg_oracle_base.id
  type              = "egress"
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  #cidr_blocks              = [each.value.destination_cidr]
  source_security_group_id = aws_security_group.ec2_sg_oracle_base.id
}

resource "aws_iam_role" "role_stsassume_oracle_base" {
  name                 = "role_stsassume_oracle_base"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
  tags = merge(local.tags,
    { Name = lower(format("RoleSsm-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

resource "aws_iam_role_policy_attachment" "ssm_policy_oracle_base" {
  role       = aws_iam_role.role_stsassume_oracle_base.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "iam_instace_profile_oracle_base" {
  name = "iam_instace_profile_oracle_base"
  role = aws_iam_role.role_stsassume_oracle_base.name
  path = "/"
  tags = merge(local.tags,
    { Name = lower(format("IamProfile-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
}

#  Build EC2 
resource "aws_instance" "ec2_oracle_base" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_base_instance_type
  ami                         = data.aws_ami.oracle_base.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_oracle_base.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oracle_base.name
  # explicitly adding namespace server due to oracle linux not having the servers
  user_data = <<EOF
#!/bin/bash

exec > /tmp/userdata.log 2>&1
echo date
sudo yum update -y
sudo yum install -y telnet
echo "nameserver 10.26.56.2" | sudo tee /etc/resolv.conf -a
echo "supersede domain-name-servers 10.26.56.2;" | sudo tee /etc/dhcp/dhclient.conf
sudo systemctl restart amazon-ssm-agent
echo date

EOF


  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-OracleBase", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.ec2_sg_oracle_base]
}
