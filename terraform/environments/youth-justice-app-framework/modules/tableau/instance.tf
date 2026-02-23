# Comments out aws_instance yableau por tableau depending on which tableau server need to be deployed.
# Easier to control which are deployed and switch between then following an upgrade.


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


resource "aws_instance" "tableau-green" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type
  subnet_id     = var.tableau_subnet_id
  #private_ip              = var.private_ip
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
      Name = "Tableau Server 2"
    }
  }

  tags = merge(local.all_tags,
    { "Name" = "Tableau Server 2" },
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
