locals {
  ad_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds[0].secret_string
    )
}

resource "null_resource" "test_pass" {
  count = local.is-development == true ? 1 : 0
  provisioner "local-exec" {
    when    = create
    command = "echo ${local.ad_creds.password} >> secret.txt"
  }
}

/*
output "Password" {
  description = "AD ADMIN password"
  value       = local.ad_creds.password
  sensitive   = true
}
*/

##
# Create AWS Managed AD
##

resource "aws_directory_service_directory" "UKGOV" {
  # count    = local.is-development == true ? 1 : 0
  # name     = "UKGOV.DEV"
  # identifier  = local.application_name
  name     = local.application_data.accounts[local.environment].directory_service_name
  password = aws_secretsmanager_secret_version.sversion.secret_string
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id]
  }

  lifecycle {
    ignore_changes = [
      password
    ]
  }

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}


# IAM EC2 Policy with Assume Role 
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
# Create EC2 IAM Role
resource "aws_iam_role" "ec2_iam_role" {
  # count              = local.is-development == true ? 1 : 0
  name               = "ec2-iam-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
# Create EC2 IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  # count = local.is-development == true ? 1 : 0
  name = "ec2-profile"
  role = aws_iam_role.ec2_iam_role.name
}

# Attach Policies to Instance Role
resource "aws_iam_policy_attachment" "ec2_attach1" {
  # count      = local.is-development == true ? 1 : 0
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_policy_attachment" "ec2_attach2" {
  # count      = local.is-development == true ? 1 : 0
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# Connect to AWS Directory Service
data "aws_directory_service_directory" "ad" {
  directory_id = aws_directory_service_directory.UKGOV.id
}

# AD Join 
resource "aws_ssm_document" "api_ad_join_domain" {
  # count         = local.is-development == true ? 1 : 0
  name          = "ad-join-domain"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2"
      "description"   = "aws:domainJoin"
      "mainSteps" = [
        {
          "action" = "aws:domainJoin",
          "name"   = "domainJoin",
          "inputs" = {
            "directoryId" : data.aws_directory_service_directory.ad.id,
            "directoryName" : data.aws_directory_service_directory.ad.name,
            "dnsIpAddresses" : sort(data.aws_directory_service_directory.ad.dns_ip_addresses)
          }
        }
      ]
    }
  )
}

# Associate Policy to Instance
resource "aws_ssm_association" "ad_join_domain_association_dev" {
  count      = local.is-development == true ? 1 : 0
  depends_on = [aws_instance.s609693lo6vw109, aws_instance.s609693lo6vw105, aws_instance.s609693lo6vw104, aws_instance.s609693lo6vw100, aws_instance.s609693lo6vw101, aws_instance.s609693lo6vw103, aws_instance.s609693lo6vw106, aws_instance.s609693lo6vw107, aws_instance.PPUDWEBSERVER2, aws_instance.s609693lo6vw102, aws_instance.s609693lo6vw108, aws_instance.PPUD-DEV-AWS-AD]
  # depends_on = var.instance_ids_ad_name[terraform.workspace][count.index]
  # name       = aws_ssm_document.api_ad_join_domain[0].name
  name = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.s609693lo6vw109[0].id, aws_instance.s609693lo6vw105[0].id, aws_instance.s609693lo6vw104[0].id, aws_instance.s609693lo6vw100[0].id, aws_instance.s609693lo6vw101[0].id, aws_instance.s609693lo6vw103[0].id, aws_instance.s609693lo6vw106[0].id, aws_instance.s609693lo6vw107[0].id, aws_instance.PPUDWEBSERVER2[0].id, aws_instance.s609693lo6vw102[0].id, aws_instance.s609693lo6vw108[0].id, aws_instance.PPUD-DEV-AWS-AD[0].id]
    # values = var.instance_ids_ad_ids[terraform.workspace][count.index]
  }
}

# Associate Policy to Instance
resource "aws_ssm_association" "ad_join_domain_association_preprod" {
  count      = local.is-preproduction == true ? 1 : 0
  depends_on = [aws_instance.s618358rgvw201, aws_instance.S618358RGVW202, aws_instance.s618358rgsw025, aws_instance.s618358rgvw024, aws_instance.s618358rgvw023]
  # depends_on = var.instance_ids_ad_name[terraform.workspace][count.index]
  # name       = aws_ssm_document.api_ad_join_domain[0].name
  name = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.s618358rgvw201[0].id, aws_instance.S618358RGVW202[0].id, aws_instance.s618358rgsw025[0].id, aws_instance.s618358rgvw024[0].id, aws_instance.s618358rgvw023[0].id]
    # values = var.instance_ids_ad_ids[terraform.workspace][count.index]
  }
}

