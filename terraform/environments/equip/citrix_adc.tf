resource "aws_instance" "citrix_adc_instance" {
  ami                    = "ami-0dd0aa051b3fc4e4b"
  instance_type          = "m5.xlarge"
  key_name               = aws_key_pair.windowskey.key_name
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.citrix_adc_mgmt.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile-moj.name
  monitoring             = true
  ebs_optimized          = true


  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
    kms_key_id  = aws_kms_key.this.arn

    tags = merge(local.tags,
          { Name = "Citrix_ADC_VPX_ROOT_VOLUME" }
      )
  }

  metadata_options {
    http_endpoint = "enabled"
    #checkov:skip=CKV_AWS_79 #tfsec:ignore:aws-ec2-enforce-http-token-imds
    http_tokens = "optional"
  }

  tags = merge(local.tags,
    { Name = "NPS-COR-A-ADC01"
      Role = "Citrix Netscaler ADC VPX"
    }
  )

}

resource "aws_network_interface" "adc_vip_interface" {
  security_groups   = [aws_security_group.citrix_adc_vip.id]
  source_dest_check = false
  subnet_id         = data.aws_subnet.public_az_a.id

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