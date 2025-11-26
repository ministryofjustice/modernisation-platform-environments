########################################
# EC2 Instances and EIPs for Mail Relays
########################################

#################################
#   Development Instances       #
#################################

# Web Server

resource "aws_instance" "PPUDWEBSERVER2" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0852d4d5313264225"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_c.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "PPUDWEBSERVER2"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Database Server

resource "aws_instance" "s609693lo6vw100" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0fbad994892c0f0c4"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-Database-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw100"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Web Server

resource "aws_instance" "s609693lo6vw101" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-07315ed3a1b524be8"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw101"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Secondary Doc Server

resource "aws_instance" "s609693lo6vw102" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0640473a9b0267bac"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Live-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw102"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Primary Doc Server

resource "aws_instance" "s609693lo6vw103" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-09bf383e2d58df1c7"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Archive-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw103"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# WAM Data Access Server

resource "aws_instance" "s609693lo6vw104" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0f115a52a37278d93"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Data-Access-Server.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw104"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# WAM Portal Server

resource "aws_instance" "s609693lo6vw105" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0edd8d3e58d106f40"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw105"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Development Server

resource "aws_instance" "s609693lo6vw106" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0f9ea6b08039bb33b"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Servers-Standard[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw106"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Development Server

resource "aws_instance" "s609693lo6vw107" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-04682227c9aa18702"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Servers-Standard[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw107"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Development Server

resource "aws_instance" "s609693lo6vw108" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0e0b7dbcff71ddd9c"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Servers-Standard[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw108"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Development Server

resource "aws_instance" "s609693lo6vw109" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-05d3600bb677c98cd"
  instance_type          = "m5.large"
  vpc_security_group_ids = [aws_security_group.SCR-Team-Foundation-Server[0].id]
  source_dest_check      = false
  subnet_id              = data.aws_subnet.private_subnets_a.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw109"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Development Server

resource "aws_instance" "s609693lo6vw110" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-09b8ade582b84853a"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Servers-Standard[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw110"
    patch_group = "dev_win_patch"
    e_volume    = "yes"
    backup      = true
  }
}

# File Server

resource "aws_instance" "s609693lo6vw111" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0cbeb839e55dbb65e"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Archive-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "s609693lo6vw111"
    patch_group = "dev_win_patch"
  }
}

# CaR Bastion

resource "aws_instance" "s609693lo6vw112" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0be53fc5198dbd294"
  instance_type          = "m5.large"
  vpc_security_group_ids = [aws_security_group.Dev-Servers-Standard[0].id]
  source_dest_check      = false
  subnet_id              = data.aws_subnet.private_subnets_a.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw112"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Development Server

resource "aws_instance" "s609693lo6vw113" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-04ffd273077ba2a8c"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Servers-Standard[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw113"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

# Development Server

resource "aws_instance" "s609693lo6vw114" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-05ca5ec6d38b0945b"
  instance_type          = "m5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Servers-Standard[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s609693lo6vw114"
    patch_group = "dev_win_patch"
    backup      = true
  }
}

#################################
# Pre-Production (UAT Instances) 
#################################

# Web Server

resource "aws_instance" "s618358rgvw023" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0f073b401ba3f1cff"
  instance_type          = "c5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s618358rgvw023"
    patch_group = "uat_win_patch"
    backup      = true
    cpu_alarm   = true
  }
}

# UAT Doc Server

resource "aws_instance" "s618358rgvw024" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-06bc4f0d8d949ba24"
  instance_type          = "m6i.2xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.UAT-Document-Service[0].id]
  subnet_id              = data.aws_subnet.data_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s618358rgvw024"
    patch_group = "uat_win_patch"
    backup      = true
    cpu_alarm   = true
    cpu_lambda_trigger = true
  }
}

# WAM Sata Access Server

resource "aws_instance" "s618358rgsw025" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0ad4be40d57ecc994"
  instance_type          = "c5.4xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Data-Access-Server.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s618358rgsw025"
    patch_group = "uat_win_patch"
    backup      = true
  }
}

# UAT Doc Server

resource "aws_instance" "s618358rgvw028" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0cbeb839e55dbb65e"
  instance_type          = "m5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.UAT-Document-Servers[0].id]
  subnet_id              = data.aws_subnet.data_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s618358rgvw028"
    patch_group = "uat_win_patch"
    backup      = true
  }
}

# WAN Portal Server

resource "aws_instance" "s618358rgvw201" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0d1cb68fb6c1f131b"
  instance_type          = "c5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "s618358rgvw201"
    patch_group = "uat_win_patch"
    backup      = true
  }
}

# UAT Bridge Server

resource "aws_instance" "S618358RGVW202" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0df4dcc477ff0fa3f"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Bridge-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "S618358RGVW202"
    patch_group = "uat_win_patch"
    backup      = true
  }
}

#########################
# Production Instances  #
#########################

# Web Server

resource "aws_instance" "s618358rgvw019" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-01d04f2e4f8cea4dd"
  instance_type          = "c5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name             = "s618358rgvw019"
    patch_group      = "prod_win_patch"
    is-production    = true
    iisadmin_service = "true"
    wwwpub_service   = "true"
    ppudlive_service = "true"
  }
}

# Web Server

resource "aws_instance" "s618358rgvw020" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0e49fc9838fdf33c4"
  instance_type          = "c5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_c.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name             = "s618358rgvw020"
    patch_group      = "prod_win_patch"
    is-production    = true
    iisadmin_service = "true"
    wwwpub_service   = "true"
    ppudlive_service = "true"
  }
}

# Database Server

resource "aws_instance" "s618358rgvw021" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-05ddec53aa481cbc3"
  instance_type          = "m5.2xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-PROD-Database[0].id]
  subnet_id              = data.aws_subnet.data_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name              = "s618358rgvw021"
    patch_group       = "prod_win_patch"
    is-production     = true
    sqlserver_service = "true"
    sqlwriter_service = "true"
    sqlagent_service  = "true"
    sqlserver_backup  = "true"
  }
}

# Primary Doc Server

resource "aws_instance" "s618358rgvw022" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-02f8251c8cdf2464f"
  instance_type          = "m5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Archive-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name                = "s618358rgvw022"
    patch_group         = "prod_win_patch"
    is-production       = true
    wwwpub_service      = "true"
    ppudlive_service    = "true"
    ppudcrawler_service = "true"
    spooler_service     = "true"
  }
}

# WAM Data Access Server

resource "aws_instance" "s618358rgsw025p" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0b8f6843db88aa8a6"
  instance_type          = "c5.4xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Data-Access-Server.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name           = "s618358rgsw025"
    patch_group    = "prod_win_patch"
    backup         = true
    wwwpub_service = "true"
  }
}

# Secondary Doc Server

resource "aws_instance" "s618358rgvw027" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0e203fec985af6465"
  instance_type          = "m5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Live-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name            = "s618358rgvw027"
    patch_group     = "prod_win_patch"
    is-production   = true
    wwwpub_service  = "true"
    spooler_service = "true"
  }
}

# WAM Portal Server

resource "aws_instance" "s618358rgvw204" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0e8380f304bd2caab"
  instance_type          = "c5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name           = "s618358rgvw204"
    patch_group    = "prod_win_patch"
    is-production  = true
    wwwpub_service = "true"
  }
}

# UAT Bridge Server

resource "aws_instance" "s618358rgvw205" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0b6b39448c2d727c3"
  instance_type          = "c5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Bridge-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name           = "s618358rgvw205"
    patch_group    = "prod_win_patch"
    is-production  = true
    wwwpub_service = "true"
  }
}

# Internal Mail Relay

resource "aws_instance" "s266316rgsl200" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0f43890c2b4907c29"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  key_name               = aws_key_pair.cjms_instance[0].key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name          = "s266316rgsl200"
    is-production = true
    patch_group   = "prod_lin_patch"
  }
}

# External non-CJSM Mail Relay

resource "aws_instance" "s265903rgsl400-non-cjsm" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0f43890c2b4907c29"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-Mail-Server-2[0].id]
  subnet_id              = data.aws_subnet.public_subnets_b.id
  key_name               = aws_key_pair.cjms_instance[0].key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name          = "s265903rgsl400-non-cjsm"
    is-production = true
    patch_group   = "prod_lin_patch"
  }
}

# External CJSM Mail Relay

resource "aws_instance" "s265903rgsl401-cjsm" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0f43890c2b4907c29"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-Mail-Server-2[0].id]
  subnet_id              = data.aws_subnet.public_subnets_c.id
  key_name               = aws_key_pair.cjms_instance[0].key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name          = "s265903rgsl401-cjsm"
    is-production = true
    patch_group   = "prod_lin_patch"
  }
}

# Docker Build Server

resource "aws_instance" "docker-build-server" {
  # checkov:skip=CKV_AWS_135: "EBS volumes are enabled by default for all PPUD EC2 instance types"
  # checkov:skip=CKV_AWS_8: "EBS volumes are encrypted by default and do not require the launch configuration encryption"
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-050d499cfdd1ff7d4"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.docker-build-server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id
  key_name               = aws_key_pair.cjms_instance[0].key_name
  root_block_device {
    delete_on_termination = true
    volume_size           = "40"
    volume_type           = "gp2"
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name          = "docker-build-server"
    is-production = true
    patch_group   = "prod_lin_patch"
  }
}

resource "aws_key_pair" "cjms_instance" {
  count      = local.is-production == true ? 1 : 0
  key_name   = "linuxcjms"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDH6T6qfPg3nUtc+A0KiWra+Alg5MyBu31FYTDvaYUY9r8ySG1+Aiz+FlV6bGQGHFaKia2GNKc/OEQ9fIs0mDDRQRoc5jtli4wwP9VtLPd7c+VdywoVvPaqAgW8KzpqTdcH8RUC1w0+12UmVlPp/RQg1b8vSVOqI0aXOVm9Faitd+YDERtJGbxdgMjaCpoJcRMjmX3omFJFU1egjOePzagOp6RZOonvGOARYat2v0yB01m7PIMwxcmP6bClx/ME9EZ6uTWYI9+wEyBwWdRYM8MV+DRe3BcepPUI/uQVJ/CDtS1f3snSKE9GKJFnUAhBp263ezZyBlidDL4L3mPzpSHV ctl\\ac97864@GBR-5CG9525GMX"
}

# resource block for eip
resource "aws_eip" "s265903rgsl400-non-cjsm" {
  count  = local.is-production == true ? 1 : 0
  domain = "vpc"
  tags = {
    Name = "s265903rgsl400-non-cjsm"
  }
}

resource "aws_eip" "s265903rgsl401-cjsm" {
  count  = local.is-production == true ? 1 : 0
  domain = "vpc"
  tags = {
    Name = "s265903rgsl401-cjsm"
  }
}


#Associate EIP for SMTP Relay EC2 Instance
resource "aws_eip_association" "s265903rgsl400-eip-association-non-cjsm" {
  count         = local.is-production == true ? 1 : 0
  instance_id   = aws_instance.s265903rgsl400-non-cjsm[0].id
  allocation_id = aws_eip.s265903rgsl400-non-cjsm[0].id
}

resource "aws_eip_association" "s265903rgsl401-eip-association-cjsm" {
  count         = local.is-production == true ? 1 : 0
  instance_id   = aws_instance.s265903rgsl401-cjsm[0].id
  allocation_id = aws_eip.s265903rgsl401-cjsm[0].id
}