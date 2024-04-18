resource "aws_s3_bucket" "mojfin_rds_oracle" {
  bucket = "mojfin-oracle-rds-${local.environment}"
}
