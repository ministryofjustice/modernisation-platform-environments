# trivy:ignore:AVD-AWS-0107 (HIGH): Security group rule allows unrestricted ingress from any IP address.
resource "aws_security_group" "importmachine" {

  # checkov:skip=CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
  # checkov:skip=CKV_AWS_260: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 80"
  # checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  # checkov:skip=CKV_AWS_25: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 3389"
  # checkov:skip=CKV_AWS_277: "Ensure no security groups allow ingress from 0.0.0.0:0 to port -1"

  description = "Configure importmachine access - ingress should be only from Bastion"
  name        = "importmachine-${local.application_name}"
  vpc_id      = local.vpc_id

 # Ingress Rules

  # RDP from Bastion
  ingress {
    description     = "RDP from Bastion"
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  # HTTP and HTTPS from LB (LB does TLS termination)
  ingress {
    description     = "HTTP from LB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.prtg_lb.id]
  }

  ingress {
    description     = "HTTPS from LB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.prtg_lb.id]
  }

  # Monitoring traffic (all protocols) restricted to environment CIDRs
  ingress {
    description      = "Monitoring traffic from environment CIDRs"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = local.environment_cidrs
  }

 # Egress Rules

  # HTTPS for updates, licence activation, external monitoring
  egress {
    description = "Allow HTTPS for updates and external monitoring"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Required for Internet access
  }

  # Monitoring traffic (all protocols) restricted to environment CIDRs
  egress {
    description      = "Monitoring traffic to environment CIDRs"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = local.environment_cidrs
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-importmachine-security-group" }
  )

}

resource "aws_key_pair" "george" {
  key_name   = "george"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt2geFOwgsihu1oAG3RghCqercNTMv1QUgVnJvyllJGllRDbD5cfit5u3yKPB50W5IOgm9p+21epSRYSEL9TwkSNuveI1LK4CFDOurT5QiOSXL/0pFScwhSFbYud3IzbMJ8dEj/hyRm+gnqHbO86CJRBvSvL6j1Wn9S1rTPbfa0VmMehTsD2Wk181TlddIUBMnG+Dd4eeIoi5ivEzfM8jX4NJXzadXG/wTIrsx471tBF7g8TzCcYDMgTQw9oEdR3wugFjfuUDSK/SYXFTUpDOufZefpENcSW9SPDVfzCeM6ludNKxZFqVGAKwc7BFMygAucZjwVgiKxWBDVRcqTmtuM+ujoBh+d/o4RVGTs9V0MSE8YSIqk91U+/PRlL1nXBk0KaLqzB6/EdZZWxkxfhzv+iDrPnvqQd+ayzV0KcbzIP6iCxFn4YDM9jPWBDjIksKhi3TB4XyW446v6ttord0eB6glWFytA1LJ7Y7aiKaOnWa5oW7IbCZtE7PFxp+dmTk= george.cairns@MJ001152"
}

resource "aws_key_pair" "gary" {
  key_name   = "gary"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCcsCSyHNsxAJmn6WbqeXC1DpD10CIiB2/rigClJ/wf+8bh+Q1SvYqU5N707gIlFOSSHyUiu25qcevyOItrLXemCkGTaCQ69qS5un3sB1ujDfU+2gk+z6ySL2UBGihr0hs2wQUsOhO3+v9AXjSbE11EGS0S6gM+yT43WkBTptMltpjOpC77pvi/b9Q9eEHjTGjtqbjYsUVxPCLrMwGcLQRfquLT5NAJL5vGmo2KvTTBs8qGTgwNWBkC4gTwoMHGQj71haChOiSNQpnHb1LjZPtMHmLHjrFmZsIHU6U/MlCtRwMYe08O7Men7BhMCfmEQ90dL+PPKVoEhFOILsSCBJ7jZpCKg+/1DF22WtZoDBt2b8eIxMj+V5NkN792nbWfrhZ0NUVbKChv9dW8c64ummhrjFqLi1hUEKRNGGM10hD7qgIfs64ke5TVu/pa2K2+6kjfEa8qMlMXY3EWvr1cPPKNzCzzeu233UfajqDrFhlgsB66T8kPBv2VfXF6c84sNpk= gary.grant@L0852"
}

resource "aws_key_pair" "ben" {
  key_name   = "ben"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLeNgZXoOyElltYhtuAbiYmU8QqsNhdPVeuDs+cVof52MtSzlRMStbfLVuui8hM9/lleUOqYW1vdQKZu2fHPuAxUTJNzN0yqKaqpSqsbnbEmUKJpMt5OGDOx6NZR6kTOoROn65p/Va8vrZ5aT5cnWNP2g54gE2Jt244OsFl4dQAtgxX+A3EB0iVbr6VS+MJ4U6zynH+xUvrYsASn9fj3HBInHFWj6g89o/JQRXwOfxeK67UKNYYP76quxPPqiabIeC+Z9eiieveSx7Y/Onjlo3tYz1LaNyiXmAPSuAvPBG0B5oftAi46VUvL6ts9s0Ifz6WvAQwbXpH7MUr6ELkGWrTeltiYmdNZweJ97y9ci4eeH3LdN2haj1D0ApSnn1/RCU9owz7cey2roqBy8pWjB0dUoyfwa0CTOYDiglB2xVuP+na/GSizlpnwOtC5HqcdHQHx5O9NZT1MqExUsQ7U5lAonjDpvwXt+Xd1AR+QAE69j1r2u/QJ/CezrIkVFqroE= ben.moore@L1451"
}

resource "aws_instance" "importmachine" {
  # checkov:skip=CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
  depends_on             = [aws_security_group.importmachine]
  instance_type          = "t3a.large"
  ami                    = local.application_data.accounts[local.environment].importmachine-ami
  vpc_security_group_ids = [aws_security_group.importmachine.id]
  monitoring             = true
  ebs_optimized          = true
  subnet_id              = data.aws_subnet.private_az_a.id
  key_name               = aws_key_pair.george.key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted   = true
    volume_size = 70
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.

      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
    ]
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "importmachine-${local.application_name}"
    }
  )
}

resource "aws_ebs_volume" "disk_xvdf" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.importmachine]
  snapshot_id       = local.application_data.accounts[local.environment].importmachine-data-snapshot
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 6000

  tags = merge(
    local.tags,
    {
      Name = "importmachine-${local.application_name}-disk"
    }
  )
}

resource "aws_volume_attachment" "disk_xvdf" {
  device_name = "xvdf"
  volume_id   = aws_ebs_volume.disk_xvdf.id
  instance_id = aws_instance.importmachine.id
}
