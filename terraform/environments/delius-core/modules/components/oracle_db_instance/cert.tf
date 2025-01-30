
data "aws_ram_resource_share" "shared_ca" {
  name = var.shared_ca_name
  resource_owner = "OTHER-ACCOUNTS"
}

data "aws_acmpca_certificate_authority" "shared_ca" {
  arn = data.aws_ram_resource_share.shared_ca.resources[0]
}

resource "aws_acmpca_certificate" "oracle_cert" {
  certificate_authority_arn = data.aws_acmpca_certificate_authority.shared_ca.arn

  csr = filebase64("${path.module}/oracle-csr.pem") # Path to your CSR file

  signing_algorithm = "SHA256WITHRSA"
  validity {
    type  = "DAYS"
    value = 365
  }

  tags = {
    Name = "OracleCertificate"
  }
}
