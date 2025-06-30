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
    "LAA-ftp-rossendales-nct-inbound-product",
    "LAA-ftp-xerox-outbound",
    "LAA-ftp-rossendales-maat-tf-outbound"
  ]
  base_buckets = ["laa-ccms-inbound", "laa-ccms-outbound","laa-ccms-ftp-lambda"]

  bucket_names = [
    for name in local.base_buckets : "${name}-${local.environment}-mp"
  ]
}

### secrets for ftp user and password
resource "aws_secretsmanager_secret" "secrets" {
  for_each = toset(local.secret_names)

  name = "${each.value}-${local.environment}"
}

resource "aws_s3_bucket" "buckets" {
  for_each = toset(local.bucket_names)

  bucket = each.value

  tags = {
    Name        = each.value
    Environment = local.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  for_each = aws_s3_bucket.buckets
  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_policy" "inbound_bucket_policy" {
  bucket = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket

  policy = jsonencode({
    "Version": "2012-10-17",
    "Id": "AccessFromMP",
    "Statement": [
        {
            "Sid": "Access_for_ccms-ebs_and_soa",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${local.environment_management.account_ids["laa-ccms-soa-${local.environment}"]}:role/ccms-soa-ec2-instance-role",
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/role_stsassume_oracle_base"
                ]
            },
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].arn,
                "${aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].arn}/*"
            ]
        }
    ]
   }
  )
}


resource "aws_s3_bucket_policy" "outbound_bucket_policy" {
  bucket = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket

  policy = jsonencode({
    "Version": "2012-10-17",
    "Id": "AccessFromMP",
    "Statement": [
        {
            "Sid": "Access_for_ccms-ebs_and_soa",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${local.environment_management.account_ids["laa-ccms-soa-${local.environment}"]}:role/ccms-soa-ec2-instance-role",
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/role_stsassume_oracle_base"
                ]
            },
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].arn,
                "${aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].arn}/*"
            ]
        }
    ]
   }
  )
}

resource "aws_s3_object" "ftp_lambda_layer" {
  bucket = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  key    = "lambda/lambda-layer.zip"
  source = "lambda/lambda-layer.zip"
}

resource "aws_s3_object" "ftp_client" {
  bucket = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  key    = "lambda/ftp-client.zip"
  source = "lambda/ftp-client.zip"
}

# #LAA-ftp-allpay-inbound-ccms
module "allpay_ftp_lambda_outbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-allpay-outbound-ccms-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_port            = "22"
  ftp_protocol        = "SFTP"
  ftp_transfer_type   = "SFTP_DOWNLOAD"
  ftp_file_types      = ""
  ftp_local_path      = "CCMS_PRD_Allpay/Inbound/"
  ftp_remote_path     = "/Outbound/"
  ftp_require_ssl     = "NO"
  ftp_insecure        = "NO"
  ftp_ca_cert         = ""
  ftp_cert            = ""
  ftp_key             = ""
  ftp_key_type        = ""
  ftp_file_remove     = "YES"
  ftp_cron            = "cron(0 10 * * ? *)"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                 = local.environment
  s3_bucket_ftp       = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_client= aws_s3_object.ftp_client.key
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  secret_name = "LAA-ftp-xerox-outbound-${local.environment}"
  skip_key_verification = "YES"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-xerox-outbound"].arn

}


#LAA-xerox-outbound-ccms
module "LAA-ftp-xerox-cis-pay-outbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-xerox-cis-pay-outbound-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id,data.aws_subnet.public_subnets_c.id]
  ftp_port            = "22"
  ftp_protocol        = "SFTP"
  ftp_transfer_type   = "SFTP_UPLOAD"
  ftp_file_types      = ""
  ftp_local_path      = "CCMS_DEV_Allpay/Outbound/"
  ftp_remote_path     = "/home/s3xfer/outbound-lambda-runs/"
  ftp_require_ssl     = "NO"
  ftp_insecure        = "NO"
  ftp_ca_cert         = ""
  ftp_cert            = ""
  ftp_key             = ""
  ftp_key_type        = ""
  ftp_file_remove     = "YES"
  ftp_cron            = "cron(0 10 * * ? *)"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  env                 = local.environment
  s3_bucket_ftp       = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_client= aws_s3_object.ftp_client.key
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  secret_name = "LAA-ftp-xerox-outbound-${local.environment}"
  skip_key_verification = "YES"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-xerox-outbound"].arn
}


# #LAA-ftp-cds-cis-pay-outbound
# module "LAA-ftp-cds-cis-pay-outbound" {
#   source              = "./modules/ftp-lambda"
#   lambda_name         = lower(format("LAA-ftp-cds-cis-pay-outbound-%s",local.environment))
#   vpc_id              = data.aws_vpc.shared.id
#   subnet_ids          = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id,data.aws_subnet.public_subnets_c.id]
#   ftp_port            = "22"
#   ftp_protocol        = "SFTP"
#   ftp_transfer_type   = "SFTP_UPLOAD"
#   ftp_file_types      = ""
#   ftp_local_path      = "CIS_PAY_DST/Outbound/"
#   ftp_remote_path     = "/Test/Outbound/PETER/"
#   ftp_require_ssl     = "NO"
#   ftp_insecure        = "NO"
#   ftp_ca_cert         = ""
#   ftp_cert            = ""
#   ftp_key             = ""
#   ftp_key_type        = ""
#   ftp_file_remove     = "YES"
#   ftp_cron            = "cron(0 10 * * ? *)"
#   ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
#   env                 = local.environment
#   s3_bucket_ftp       = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
#   s3_object_ftp_client= aws_s3_object.ftp_client.key
#   s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key

# }