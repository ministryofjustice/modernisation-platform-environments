locals {
  ad_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

resource "null_resource" "test_pass" {
  provisioner "local-exec" {
    when    = create
    command = "echo ${local.ad_creds.password} >> secret.txt"
  }
}

output "Password" {
  description = "AD ADMIN password"
  value       = local.ad_creds.password
  sensitive = true
}

resource "aws_directory_service_directory" "TESTAD" {
  name     = "rayconsultant.com"
  password = local.ad_creds.password
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = data.aws_vpc.shared.id
    subnet_ids = [data.aws_subnet.public_subnets_a.id,data.aws_subnet.public_subnets_b.id]
  }
/*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
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
   name                = "ec2-iam-role"
   path                = "/"
   assume_role_policy  = data.aws_iam_policy_document.ec2_assume_role.json
 }
# Create EC2 IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_iam_role.name
}
# Attach Policies to Instance Role
resource "aws_iam_policy_attachment" "ec2_attach1" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_policy_attachment" "ec2_attach2" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# Connect to AWS Directory Service
data "aws_directory_service_directory" "ad" {
  directory_id = aws_directory_service_directory.TESTAD.id
}

# AD Join 
resource "aws_ssm_document" "api_ad_join_domain" {
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
          "directoryId": data.aws_directory_service_directory.ad.id,
          "directoryName" : data.aws_directory_service_directory.ad.name,
          "dnsIpAddresses" : sort(data.aws_directory_service_directory.ad.dns_ip_addresses)
          }
        }
      ]
    }
  )
}

# Associate Policy to Instance

/*
resource "aws_ssm_association" "ad_join_domain_association" {
  depends_on = [aws_instance.Windowstest]
  name = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.Windowstest.id]
  }
}

*/
resource "aws_ssm_association" "ad_join_domain_association1" {
  depends_on = [aws_instance.Windows2,aws_instance.Windowstest,aws_instance.Windows3]
  name = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.Windows2.id,aws_instance.Windowstest.id,aws_instance.Windows3.id]
  }
}
/*
resource "aws_ssm_association" "ad_join_domain_association2" {
  depends_on = [aws_instance.Windows3]
  name = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.Windows3.id]
  }
}
*/