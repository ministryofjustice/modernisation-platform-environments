resource "aws_iam_instance_profile" "tableau" {
    name = "TableauServer"
    role = "${aws_iam_role.ec2-tableau-role.name}"
}

resource "aws_instance" "tableau" {
  ami                     = data.aws_ami.app_ami.id
  instance_type           = var.instance_type
  subnet_id               = var.tableau_subnet_id
  private_ip              = var.private_ip
  vpc_security_group_ids  = ["${module.tableau_sg.security_group_id}"]
  disable_api_termination = local.disable_api_termination

  key_name             = module.key_pair.key_pair_name 
  iam_instance_profile = aws_iam_instance_profile.tableau.name

 # user_data = (templatefile("tableau_init.sh.tftpl",
 #   {
 #     dd_api_key_secret_arn = data.aws_secretsmanager_secret.datadog-api-key.id,
 #     instance_role         = "tableau"
 # }))

  root_block_device {
    delete_on_termination = local.delete_on_termination
    encrypted             = true
    volume_size           = var.instance_volume_size
    tags = {
      Name = "Tableau Server"
    }
  }

  tags = {
    Name          = "Tableau Server"
    Build         = "${data.aws_ami.app_ami.name}"
    PatchSchedule = var.patch_schedule
    Schedule      = var.availability_schedule
    OS            = "Linux"
    Owner         = "Devops"
  }
}

module "tableau-alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = var.alb_name
  vpc_id  = var.vpc_id
  subnets = var.alb_subnet_ids

  security_groups       = [module.alb_sg.security_group_id]
  create_security_group = false

  enable_deletion_protection = local.enable_deletion_protection

  access_logs = {
    bucket = local.tableau_alb_logs_arn
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
      source_security_group_id = "${module.tableau_sg.security_group_id}"
      description              = "Public ALB to Tableau server"
    }
  ]
}



module "tableau_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Tableau Server"
  description = "Control access to and from Tableau Servers"

  ingress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "10.20.10.0/24"
      description = "Tableau website access from management servers"
    },
    {
      from_port   = 8850
      to_port     = 8850
      protocol    = 6
      description = "Tableau admin site access from management servers"
      cidr_blocks = "10.20.10.0/24"
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "10.20.10.0/24"
      description = "SSH access from management servers"
    },
  ]

  ingress_with_source_security_group_id = [
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.alb_sg.security_group_id
    },

  ]

  egress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "Tableau server outbound access for sofware updates."
    },
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "ldap-tcp"
      source_security_group_id = var.directory_service_sg_id
    },
    {
      rule                     = "ldaps-tcp"
      source_security_group_id = var.directory_service_sg_id
    },
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = var.postgresql_sg_id
    },
    {
      rule                     = "redshift-tcp"
      source_security_group_id = var.redshift_sg_id
    },
  ]
}

module "directory_service_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id            = var.vpc_id
  security_group_id = var.directory_service_sg_id
  create_sg         = false

  ingress_with_source_security_group_id = [
    {
      rule                     = "ldap-tcp"
      source_security_group_id = module.tableau_sg.security_group_id
    },
    {
      rule                     = "ldaps-tcp"
      source_security_group_id = module.tableau_sg.security_group_id
    },
  ]
}

module "postgresql_sg" {
  source = "./add_rules_to_sg"

  vpc_id       = var.vpc_id
  source_sg_id = module.tableau_sg.security_group_id
  target_sg_id = var.postgresql_sg_id
  rule         = "postgresql-tcp"
  description  = "Inbound from Tableau"
}

module "redshift_sg" {
  source = "./add_rules_to_sg"

  vpc_id       = var.vpc_id
  source_sg_id = module.tableau_sg.security_group_id
  target_sg_id = var.redshift_sg_id
  rule         = "redshift-tcp"
  description  = "Redshift from Tableau Server."

}
