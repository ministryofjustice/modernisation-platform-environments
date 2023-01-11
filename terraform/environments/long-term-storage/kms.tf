resource "aws_kms_key" "hmpps_intranet" {
  description = "KMS key to encrypt the HMPPS Intranet EBS volume"
}
