locals {
    secret_names = [
    "LAA-ftp-allpay-inbound-ccms",
    "LAA-ftp-tdx-inbound-ccms-agencyassigmen",
    "LAA-ftp-rossendales-ccms-csv-inbound",
    "LAA-ftp-rossendales-maat-inbound",
    "LAA-ftp-tdx-inbound-ccms-activity",
    "LAA-ftp-tdx-inbound-ccms-transaction",
    "LAA-ftp-tdx-inbound-ccms-livelist",
    "LAA-ftp-tdx-inbound-ccms-multiplefiles",
    "LAA-ftp-rossendales-ccms-inbound",
    "LAA-ftp-tdx-inbound-ccms-agencyrecallre",
    "LAA-ftp-tdx-inbound-ccms-nonfinancialup",
    "LAA-ftp-tdx-inbound-ccms-exceptionnotif",
    "LAA-ftp-eckoh-inbound-ccms",
    "LAA-ftp-1stlocate-ccms-inbound",
    "LAA-ftp-rossendales-nct-inbound-product"
  ]
}


### secrets for ftp user and password
resource "aws_secretsmanager_secret" "secrets" {
  for_each = toset(local.secret_names)

  name = "${each.value}-${local.environment}"
}
