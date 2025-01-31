
data "aws_ram_resource_share" "shared_ca" {
  name = var.shared_ca_name
  resource_owner = "OTHER-ACCOUNTS"
}

data "aws_acmpca_certificate_authority" "shared_ca" {
  arn = data.aws_ram_resource_share.shared_ca.resource_arns[0]
}

# resource "tls_private_key" "key" {
#   algorithm = "RSA"
# }

# resource "tls_cert_request" "csr" {
#   private_key_pem = tls_private_key.key.private_key_pem

#   subject {
#     common_name = "example"
#   }
# }

# resource "aws_acmpca_certificate" "oracle_cert" {
#   certificate_authority_arn = data.aws_acmpca_certificate_authority.shared_ca.arn
#   certificate_signing_request = tls_cert_request.csr.cert_request_pem
#   signing_algorithm           = "SHA256WITHRSA"
#   validity {
#     type  = "YEARS"
#     value = 1
#   }
# }

