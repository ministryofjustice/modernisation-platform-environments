resource "aws_directory_service_directory" "UKGOV" {
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

# Connect to AWS Directory Service
data "aws_directory_service_directory" "ad" {
  directory_id = aws_directory_service_directory.UKGOV.id
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
            "directoryId" : data.aws_directory_service_directory.ad.id,
            "directoryName" : data.aws_directory_service_directory.ad.name,
            "dnsIpAddresses" : sort(data.aws_directory_service_directory.ad.dns_ip_addresses)
          }
        }
      ]
    }
  )
}

# Associate Policy to Development Instance
resource "aws_ssm_association" "ad_join_domain_association_dev" {
  count      = local.is-development == true ? 1 : 0
  depends_on = [aws_instance.s609693lo6vw109, aws_instance.s609693lo6vw105, aws_instance.s609693lo6vw104, aws_instance.s609693lo6vw100, aws_instance.s609693lo6vw101, aws_instance.s609693lo6vw103, aws_instance.s609693lo6vw106, aws_instance.s609693lo6vw107, aws_instance.PPUDWEBSERVER2, aws_instance.s609693lo6vw102, aws_instance.s609693lo6vw108, aws_instance.s609693lo6vw110, aws_instance.s609693lo6vw111, aws_instance.s609693lo6vw112, aws_instance.s609693lo6vw113]
  name       = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.s609693lo6vw109[0].id, aws_instance.s609693lo6vw105[0].id, aws_instance.s609693lo6vw104[0].id, aws_instance.s609693lo6vw100[0].id, aws_instance.s609693lo6vw101[0].id, aws_instance.s609693lo6vw103[0].id, aws_instance.s609693lo6vw106[0].id, aws_instance.s609693lo6vw107[0].id, aws_instance.PPUDWEBSERVER2[0].id, aws_instance.s609693lo6vw102[0].id, aws_instance.s609693lo6vw108[0].id, aws_instance.s609693lo6vw110[0].id, aws_instance.s609693lo6vw111[0].id, aws_instance.s609693lo6vw112[0].id, aws_instance.s609693lo6vw113[0].id]
  }
}

# Associate Policy to UAT Instance
resource "aws_ssm_association" "ad_join_domain_association_preprod" {
  count      = local.is-preproduction == true ? 1 : 0
  depends_on = [aws_instance.s618358rgvw201, aws_instance.S618358RGVW202, aws_instance.s618358rgsw025, aws_instance.s618358rgvw024, aws_instance.s618358rgvw023, aws_instance.s618358rgvw028]
  name       = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.s618358rgvw201[0].id, aws_instance.S618358RGVW202[0].id, aws_instance.s618358rgsw025[0].id, aws_instance.s618358rgvw024[0].id, aws_instance.s618358rgvw023[0].id, aws_instance.s618358rgvw028[0].id]
  }
}


# Associate Policy to PROD Instance
resource "aws_ssm_association" "ad_join_domain_association_prod" {
  count      = local.is-production == true ? 1 : 0
  depends_on = [aws_instance.s618358rgvw019, aws_instance.s618358rgvw020, aws_instance.s618358rgvw021, aws_instance.s618358rgvw022, aws_instance.s618358rgvw027, aws_instance.s618358rgvw204, aws_instance.s618358rgvw205, aws_instance.s618358rgsw025p]
  name       = aws_ssm_document.api_ad_join_domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.s618358rgvw019[0].id, aws_instance.s618358rgvw020[0].id, aws_instance.s618358rgvw021[0].id, aws_instance.s618358rgvw022[0].id, aws_instance.s618358rgvw027[0].id, aws_instance.s618358rgvw204[0].id, aws_instance.s618358rgvw205[0].id, aws_instance.s618358rgsw025p[0].id]
  }
}
