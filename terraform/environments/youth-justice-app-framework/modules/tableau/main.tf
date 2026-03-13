resource "aws_iam_instance_profile" "tableau" {
  name = "TableauServer"
  role = aws_iam_role.ec2_tableau_role.name
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
      target_id   = var.tableau_blue_live ? aws_instance.tableau.id : aws_instance.tableau-green.id
    }
  }
}
#trivy:ignore:AVD-AWS-0052 - needs testing in non-prod first
#trivy:ignore:AVD-AWS-0053
module "tableau-test-alb" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/alb/aws"
  version = "9.13.0"

  count = var.tableau_test_active ? 1 : 0

  name    = "${var.alb_name}-test"
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
      certificate_arn = var.test_certificate_arn

      forward = {
        target_group_key = "tableau-test-instance"
      }
    }

  }

  target_groups = {
    tableau-test-instance = {
      protocol    = "HTTPS"
      port        = 443
      target_type = "instance"
      target_id   = var.tableau_blue_live ? aws_instance.tableau-green.id : aws_instance.tableau.id
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
