resource "aws_instance" "citrix_adc_instance" {
  ami                    = "ami-0dd0aa051b3fc4e4b"
  instance_type          = "m5.xlarge"
  key_name               = aws_key_pair.windowskey.key_name
  subnet_id              = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids = [aws_security_group.citrix_adc.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile-moj.name
  monitoring             = true
  ebs_optimized          = true


  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
    kms_key_id  = aws_kms_key.this.arn

    tags = {
      Name = "Citrix_ADC_VPX_ROOT_VOLUME"
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    #checkov:skip=CKV_AWS_79 #tfsec:ignore:aws-ec2-enforce-http-token-imds
    http_tokens = "optional"
  }

  tags = {
    Name = "NPS-COR-A-ADC01"
    ROLE = "Citrix Netscaler ADC VPX"
  }
}

