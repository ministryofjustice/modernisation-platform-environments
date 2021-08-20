#### Networking & Security ####

# get shared subnet-set vpc object
data "aws_vpc" "shared_vpc" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}"
  }
}

data "aws_subnet_ids" "local_account" {
  vpc_id = data.aws_vpc.shared_vpc.id
}

data "aws_subnet" "local_account" {
  for_each = data.aws_subnet_ids.local_account.ids
  id       = each.value
}

# get shared subnet-set private (az (a) subnet)
data "aws_subnet" "private_az_a" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

# get bastion_linux security group
data "aws_security_group" "bastion_linux" {
  provider = aws.share-host

  tags = {
    Name = "bastion-linux-${local.application_name}"
  }
}

# Security Groups
resource "aws_security_group" "weblogic_server" {
  description = "Configure weblogic access - ingress should be only from Bastion"
  name        = "weblogic-server-${local.application_name}"
  vpc_id      = data.aws_vpc.shared_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "weblogic-server-${local.application_name}"
    }
  )
}


resource "aws_security_group_rule" "weblogic_server_egress_1" {
  security_group_id = aws_security_group.weblogic_server.id

  description = "weblogic_server_ingress_of_SSH_from_Bastion"
  type        = "ingress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "TCP"
  # cidr_blocks = ["0.0.0.0/0"]
  source_security_group_id = data.aws_security_group.bastion_linux.id
}

##### EC2 ####

data "aws_ami" "weblogic_image" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat - this will be a custom image later "self"

  filter {
    name   = "name"
    values = ["RHEL-6.9*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "weblogic_server" {
  instance_type = "t3.micro"

  ami                         = data.aws_ami.weblogic_image.id
  associate_public_ip_address = false
  # iam_instance_profile        = aws_iam_instance_profile.bastion_profile.id
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.weblogic_server.id]
  subnet_id              = data.aws_subnet.private_az_a.id

  # user_data = base64encode(data.template_file.user_data.rendered)

  tags = merge(
    var.tags,
    {
      Name = "weblogic"
    }
  )
}