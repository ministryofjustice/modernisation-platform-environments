resource "aws_ec2_subnet_cidr_reservation" "vip-reservation" {
  provider         = aws.core-vpc
  cidr_block       = cidrsubnet(data.aws_subnet.public_subnets_a.cidr_block, 5, 30)
  reservation_type = "explicit"
  subnet_id        = data.aws_subnet.public_subnets_a.id
}

resource "aws_ec2_subnet_cidr_reservation" "snip-reservation" {
  provider         = aws.core-vpc
  cidr_block       = cidrsubnet(data.aws_subnet.private_subnets_a.cidr_block, 6, 62)
  reservation_type = "explicit"
  subnet_id        = data.aws_subnet.private_subnets_a.id
}

resource "aws_eip" "public-vip" {
  #checkov:skip=CKV2_AWS_19: "EIP attachment is handled through separate resource"
  tags = merge(local.tags,
  { Name = "EIP-ADC-Public" })
}

resource "aws_eip_association" "public-vip" {
  allocation_id        = aws_eip.public-vip.id
  network_interface_id = aws_network_interface.adc_vip_interface.id
  private_ip_address   = aws_network_interface.adc_vip_interface.private_ip
}

resource "aws_network_interface" "adc_mgmt_interface" {
  security_groups   = [aws_security_group.citrix_adc_mgmt.id]
  source_dest_check = false
  subnet_id         = data.aws_subnet.data_subnets_a.id

  tags = merge(local.tags,
    { Name = "ENI-NPS-COR-A-ADC01_MGMT"
      ROLE = "Citrix Netscaler ADC VPX MGMT Interface"
    }
  )
}

resource "aws_network_interface" "adc_vip_interface" {
  depends_on              = [aws_ec2_subnet_cidr_reservation.vip-reservation]
  private_ip_list_enabled = true
  private_ip_list = [
    cidrhost(aws_ec2_subnet_cidr_reservation.vip-reservation.cidr_block, 0),
    cidrhost(aws_ec2_subnet_cidr_reservation.vip-reservation.cidr_block, 1),
  ]
  security_groups   = [aws_security_group.citrix_adc_vip.id]
  source_dest_check = false
  subnet_id         = data.aws_subnet.public_subnets_a.id

  attachment {
    device_index = 1
    instance     = aws_instance.citrix_adc_instance.id
  }

  tags = merge(local.tags,
    { Name = "ENI-NPS-COR-A-ADC01_VIP"
      ROLE = "Citrix Netscaler ADC VPX VIP Interface"
    }
  )
}

resource "aws_network_interface" "adc_snip_interface" {
  depends_on              = [aws_ec2_subnet_cidr_reservation.snip-reservation]
  private_ip_list_enabled = true
  private_ip_list = [
    cidrhost(aws_ec2_subnet_cidr_reservation.snip-reservation.cidr_block, 0),
    cidrhost(aws_ec2_subnet_cidr_reservation.snip-reservation.cidr_block, 1),
    cidrhost(aws_ec2_subnet_cidr_reservation.snip-reservation.cidr_block, 2),
    cidrhost(aws_ec2_subnet_cidr_reservation.snip-reservation.cidr_block, 3),
  ]
  security_groups   = [aws_security_group.citrix_adc_snip.id]
  source_dest_check = false
  subnet_id         = data.aws_subnet.private_subnets_a.id

  attachment {
    device_index = 2
    instance     = aws_instance.citrix_adc_instance.id
  }

  tags = merge(local.tags,
    { Name = "ENI-NPS-COR-A-ADC01_SNIP"
      ROLE = "Citrix Netscaler ADC VPX SNIP Interface"
    }
  )
}
