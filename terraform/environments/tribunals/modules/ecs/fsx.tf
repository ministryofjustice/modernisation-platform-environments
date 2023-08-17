
resource "random_password" "ad_password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true
}

# Creating a AWS secret for AWS managed AD
resource "aws_secretsmanager_secret" "secretdirectoryservice" {
  name                    = "${var.app_name}-AWSADPASS"
  recovery_window_in_days = 0
}

# Creating a AWS secret versions for AWS managed AD
resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id     = aws_secretsmanager_secret.secretdirectoryservice.id
  secret_string = random_password.ad_password.result
}

# resource "aws_directory_service_directory" "transport_ad" {
#   name     = "${local.transport}.AD"
#   password = aws_secretsmanager_secret_version.sversion.secret_string
#   edition  = "Standard"
#   type     = "MicrosoftAD"

#   vpc_settings {
#     vpc_id     = data.aws_vpc.shared.id
#     subnet_ids = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id]
#   }

#   lifecycle {
#     ignore_changes = [
#       password
#     ]
#   }

#   tags = {
#     Name = "${local.transport}-${var.networking[0].business-unit}-${local.environment}"
#   }
# }

resource "aws_fsx_windows_file_system" "app_fsx" {

  #active_directory_id = "${aws_directory_service_directory.transport_ad.id}"
  storage_capacity    = 300
  subnet_ids          = [data.aws_subnets.shared-public.ids[0]]
  security_group_ids  = [aws_security_group.cluster_ec2.id]
  throughput_capacity = 8

  self_managed_active_directory {
    dns_ips     = ["35.177.233.142"]
    domain_name = "modernisation-platform.service.justice.gov.uk"
    password    = aws_secretsmanager_secret_version.sversion.secret_string
    username    = "Admin"
  }

  tags = {
    Project     = "${local.transport}"
    Environment = "${local.environment}"
  }
}