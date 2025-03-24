#create keypair for ec2 instances
module "key_pair" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/key-pair/aws"
  version = "2.0.3"

  key_name           = "esb-ec2-keypair"
  create_private_key = true

  tags = local.all_tags
}


data "template_file" "userdata" {
  template = file("${path.module}/ec2-userdata.tftpl")
  vars = {
    env          = var.environment
    tags         = jsonencode(local.all_tags)
    project      = var.project_name
  }
}



resource "aws_instance" "esb" {
  ami                    = "ami-0fc27ddcf3e4e76af"
  instance_type          = "t3a.xlarge"  
  key_name               = module.key_pair.key_pair_name     
  monitoring             = true
  ebs_optimized          = true
  iam_instance_profile   = aws_iam_instance_profile.esb_ec2_profile.id
  vpc_security_group_ids = [aws_security_group.esb_service.id]
  subnet_id              = var.subnet_id
  tags                   = local.all_tags





  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }   
  
  
  root_block_device {
    encrypted             = true
    delete_on_termination = false
    volume_size           = 60
    volume_type           = "gp2"
  }

}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}