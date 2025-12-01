resource "aws_iam_instance_profile" "tableau" {
  name = "TableauServer"
  role = aws_iam_role.ec2_tableau_role.name
}

resource "aws_instance" "tableau" {
  ami                     = data.aws_ami.app_ami.id
  instance_type           = var.instance_type
  subnet_id               = var.tableau_subnet_id
  private_ip              = var.private_ip
  vpc_security_group_ids  = [module.tableau_sg.security_group_id]
  disable_api_termination = local.disable_api_termination

  key_name             = module.key_pair.key_pair_name
  iam_instance_profile = aws_iam_instance_profile.tableau.name

  metadata_options {
    http_tokens = "required"
  }

  ebs_optimized = true

  user_data = (templatefile("${path.module}/tableau_init.sh.tftpl",
    {
      dd_api_key_secret_arn = var.datadog_api_key_arn,
      instance_role         = "tableau"
  }))

  root_block_device {
    delete_on_termination = local.delete_on_termination
    encrypted             = true
    volume_size           = var.instance_volume_size
    tags = {
      Name = "Tableau Server"
    }
  }

  tags = merge(local.all_tags,
    { "Name" = "Tableau Server" },
    { "Build" = data.aws_ami.app_ami.name },
    { "PatchSchedule" = var.patch_schedule },
    { "OS" = "Linux" },
    { "Owner" = "Devops" }
  )

  ## Create using the latest version of the ami but do not replace when a new version is repeased. 
  lifecycle {
    ignore_changes = [ami]
  }

}
#trivy:ignore:AVD-AWS-0052 - needs testing in non-prod first
#trivy:ignore:AVD-AWS-0053
module "tableau-alb" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/alb/aws"
  version = "9.13.0"

  name    = var.alb_name
  vpc_id  = var.vpc_id
  subnets = var.alb_subnet_ids

  security_groups       = [module.alb_sg.security_group_id]
  create_security_group = false

  enable_deletion_protection = local.enable_deletion_protection

  # LB Attributes
  idle_timeout               = 360
  drop_invalid_header_fields = false

  access_logs = {
    bucket = module.log_bucket.s3_bucket_id
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      proticol = "HTTP"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn

      forward = {
        target_group_key = "tableau-instance"
      }
    }

  }

  target_groups = {
    tableau-instance = {
      protocol    = "HTTPS"
      port        = 443
      target_type = "instance"
      target_id   = aws_instance.tableau.id
    }
  }
}


module "alb_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Tableau ALB Allow All"
  description = "Public Access to Tableau via ALB"

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.tableau_sg.security_group_id
      description              = "Public ALB to Tableau server"
    }
  ]
}
