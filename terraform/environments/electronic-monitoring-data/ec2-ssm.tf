#------------------------------------------------------------------------------
# Security group rule addition
#------------------------------------------------------------------------------
resource "aws_security_group" "ec2_bastion" {
  name        = "ec2-bastion"
  description = "Allow ec2 access"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_egress_rule" "mssql_access" {
  security_group_id = aws_security_group.ec2_bastion.id
  description       = "EC2 MSSQL Access"
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "vpc_access" {
  security_group_id = aws_security_group.ec2_bastion.id
  description       = "Reach vpc endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "vpc_access" {
  security_group_id            = aws_security_group.db.id
  description                  = "Ec2 instance"
  ip_protocol                  = "tcp"
  from_port                    = 1433
  to_port                      = 1433
  referenced_security_group_id = aws_security_group.ec2_bastion.id
}

#------------------------------------------------------------------------------
# IAM to access database
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2-rds-access-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2-instance" {
  name               = "instance-role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.ec2-rds-access-role.json
}

resource "aws_iam_policy_attachment" "ssm-attachments" {
  name       = "ssm-attach-instance-role"
  roles      = [aws_iam_role.ec2-instance.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2-instance" {
  name = "instance-role"
  role = aws_iam_role.ec2-instance.name
}

resource "aws_iam_policy" "ec2_rds_s3_policy" {
  name        = "ec2-s3-policy"
  description = "Policy for s3 actions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_s3_attachment" {
  role       = aws_iam_role.ec2-instance.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

#------------------------------------------------------------------------------
# Instance definition
#------------------------------------------------------------------------------

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.this.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.private_subnets_b.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2-instance.name
  security_groups             = [aws_security_group.ec2_bastion.id]
  tags = merge(
    local.tags,
    { Name = "rds-bastion" }
  )
}
