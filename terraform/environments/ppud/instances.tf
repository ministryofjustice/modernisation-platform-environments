#################################
#   Development Instances       #
#################################

resource "aws_instance" "s609693lo6vw109" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0ca7365d53b8b8028"
  instance_type          = "m5.large"
  vpc_security_group_ids = [aws_security_group.SCR-Team-Foundation-Server[0].id]
  source_dest_check      = false
  subnet_id              = data.aws_subnet.private_subnets_a.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  tags = {
    Name   = "s609693lo6vw109"
    backup = true
  }
}

resource "aws_instance" "s609693lo6vw105" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0edd8d3e58d106f40"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name = "s609693lo6vw105"
  }
}

resource "aws_instance" "s609693lo6vw104" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0f115a52a37278d93"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Data-Access-Server.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name = "s609693lo6vw104"
  }
}

resource "aws_instance" "s609693lo6vw100" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0fbad994892c0f0c4"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-Database-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name   = "s609693lo6vw100"
    backup = true
  }
}

resource "aws_instance" "s609693lo6vw101" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0fe72f8cd9b3d4df6"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  tags = {
    Name = "s609693lo6vw101"
  }
}

resource "aws_instance" "s609693lo6vw103" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-09bf383e2d58df1c7"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Primary-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  tags = {
    Name = "s609693lo6vw103"
  }
}

resource "aws_instance" "s609693lo6vw106" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0f9ea6b08039bb33b"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Box-VW106[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  tags = {
    Name = "s609693lo6vw106"
  }
}

resource "aws_instance" "s609693lo6vw107" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-04682227c9aa18702"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Box-VW107[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  tags = {
    Name = "s609693lo6vw107"
  }
}

resource "aws_instance" "PPUDWEBSERVER2" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-06135685d04b2ebea"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_c.id
  tags = {
    Name = "PPUDWEBSERVER2"
  }
}

resource "aws_instance" "s609693lo6vw102" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0640473a9b0267bac"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Secondary-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id
  tags = {
    Name = "s609693lo6vw102"
  }
}

resource "aws_instance" "s609693lo6vw108" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-0e0b7dbcff71ddd9c"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Dev-Box-VW108[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id
  tags = {
    Name = "s609693lo6vw108"
  }
}

resource "aws_instance" "PPUD-DEV-AWS-AD" {
  count                  = local.is-development == true ? 1 : 0
  ami                    = "ami-04a9f465215b89a4b"
  instance_type          = "t2.micro"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-DEV-AD.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name   = "PPUD-DEV-AWS-AD"
    backup = true
  }
}

#################################
# Pre-Production (UAT Instances) #
#################################


resource "aws_instance" "s618358rgvw201" {
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0d1cb68fb6c1f131b"
  instance_type          = "c5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name   = "s618358rgvw201"
    backup = true
  }
}

resource "aws_instance" "S618358RGVW202" {
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0df4dcc477ff0fa3f"
  instance_type          = "m5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Bridge-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name   = "S618358RGVW202"
    backup = true
  }
}

resource "aws_instance" "s618358rgsw025" {
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0ad4be40d57ecc994"
  instance_type          = "c5.4xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.WAM-Data-Access-Server.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name   = "s618358rgsw025"
    backup = true
  }
}

resource "aws_instance" "s618358rgvw024" {
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-0d3d8251678e13330"
  instance_type          = "m6i.2xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.UAT-Document-Service[0].id]
  subnet_id              = data.aws_subnet.data_subnets_a.id
  tags = {
    Name   = "s618358rgvw024"
    backup = true
  }
}

resource "aws_instance" "s618358rgvw023" {
  count                  = local.is-preproduction == true ? 1 : 0
  ami                    = "ami-04944a7de56185ec3"
  instance_type          = "c5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  tags = {
    Name   = "s618358rgvw023"
    backup = true
  }
}

#########################
# Production Instances  #
#########################

resource "aws_instance" "s618358rgvw019" {
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-053a1bdfccde5a440"
  instance_type          = "c5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  tags = {
    Name          = "s618358rgvw019"
    is-production = true
  }
}

resource "aws_instance" "s618358rgvw020" {
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0f40fd8eeb25ed216"
  instance_type          = "c5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_c.id
  tags = {
    Name          = "s618358rgvw020"
    is-production = true
  }
}

resource "aws_instance" "s618358rgvw021" {
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-06f04ef58ddbec1fb"
  instance_type          = "m5.2xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-PROD-Database[0].id]
  subnet_id              = data.aws_subnet.data_subnets_a.id
  tags = {
    Name          = "s618358rgvw021"
    is-production = true
  }
}

resource "aws_instance" "s618358rgvw022" {
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-099e1bff1ed376c3c"
  instance_type          = "m5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Primary-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_b.id
  tags = {
    Name          = "s618358rgvw022"
    is-production = true
  }
}

resource "aws_instance" "s618358rgvw027" {
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0d47d882709bccb38"
  instance_type          = "m5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Secondary-DOC-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_c.id
  tags = {
    Name          = "s618358rgvw027"
    is-production = true
  }
}

resource "aws_instance" "s618358rgvw204" {
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0e570893d0761b36d"
  instance_type          = "c5.xlarge"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.PPUD-WEB-Portal.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name          = "s618358rgvw204"
    is-production = true
  }
}

resource "aws_instance" "S618358RGVW205" {
  count                  = local.is-production == true ? 1 : 0
  ami                    = "ami-0e863bfbce3cfe8eb"
  instance_type          = "c5.large"
  source_dest_check      = false
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.Bridge-Server[0].id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  tags = {
    Name          = "S618358RGVW205"
    is-production = true
  }
}
