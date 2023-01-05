data "aws_ami" "amzLinuxX86gp2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel*-hvm*x86_64-gp2*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# First build the security group for the EC2
resource "aws_security_group" "ec2_sg_igs_dom1_web_proxy" {
  name        = "ec2_sg_igs_dom1_web_proxy"
  description = "Controls access to EC2 web server for IGS DOM1 proxy testing"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-IgsDom1WebProxy", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ec2_sg_ingress_rules_igs_dom1_web_proxy_http" {
  for_each          = local.application_data.ec2_sg_ingress_rules_igs_dom1_web_proxy_http
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.ec2_sg_igs_dom1_web_proxy.id
  to_port           = each.value.to_port
  type              = "ingress"
  #cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ec2_sg_ingress_rules_igs_dom1_web_proxy_ssh" {
  for_each          = local.application_data.ec2_sg_ingress_rules_igs_dom1_web_proxy_ssh
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.ec2_sg_igs_dom1_web_proxy.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_traffic_igs_dom1_web_proxy" {
  for_each                 = local.application_data.ec2_sg_egress_rules_igs_dom1_web_proxy
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.ec2_sg_igs_dom1_web_proxy.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.ec2_sg_igs_dom1_web_proxy.id
}



#  Build EC2 
resource "aws_instance" "ec2_igs_dom1_web_proxy" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type               = local.application_data.accounts[local.environment].ec2_igs_dom1_web_proxy_instance_type
  ami                         = data.aws_ami.amzLinuxX86gp2.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg_igs_dom1_web_proxy.id]
  subnet_id                   = data.aws_subnet.public_subnets_a.id
  monitoring                  = true
  user_data_base64            = base64encode(templatefile("${path.module}/scripts/bootstrap_igs_dom1_web_proxy.sh.tftpl", {}))
  associate_public_ip_address = true

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
    { Name = lower(format("ec2-%s-%s-IgsDom1WebProxy", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.ec2_sg_igs_dom1_web_proxy]
}
