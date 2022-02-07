
# Security Groups
resource "aws_security_group" "nat-server" {
  description = "nat traffic"
  name        = "nat-server-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "nat-smtp-from-exchange" {
  depends_on               = [aws_security_group.nat-server]
  security_group_id        = aws_security_group.nat-server.id
  type                     = "ingress"
  description              = "allow port 25"
  from_port                = 25
  to_port                  = 25
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.app-server.id
}

resource "aws_security_group_rule" "nat-smtp-outbound-to-web" {
  depends_on        = [aws_security_group.nat-server]
  security_group_id = aws_security_group.nat-server.id
  type              = "egress"
  description       = "allow port 25"
  from_port         = 25
  to_port           = 25
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]

}


resource "aws_eip" "smtp-nat" {
  instance = aws_instance.nat-server.id
  vpc      = true
}

# resource "aws_route" "exchange-to-nat" {
#   route_table_id            = 
#   destination_cidr_block    = 
#   gateway_id                =
# }

resource "aws_instance" "nat-server" {
  depends_on                  = [aws_security_group.nat-server]
  instance_type               = "t2.medium"
  ami                         = local.application_data.accounts[local.environment].nat-instance-ami
  vpc_security_group_ids      = [aws_security_group.nat-server.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.public_az_a.id
  key_name                    = aws_key_pair.george.key_name


  user_data = <<EOF
#!/bin/bash

sudo sysctl -w net.ipv4.ip_forward=1
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo yum install iptables-services
sudo service iptables save


  EOF


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
  }

  tags = merge(
    local.tags,
    {
      Name = "nat-${local.application_name}"
    }
  )
}

