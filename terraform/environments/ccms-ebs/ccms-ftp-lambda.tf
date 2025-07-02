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
  base_buckets = ["laa-ccms-inbound", "laa-ccms-outbound"]

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



# #LAA-ftp-allpay-outbound-ccms
module "allpay_ftp_lambda_outbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-allpay-outbound-ccms-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type   = "SFTP_UPLOAD"
  ftp_local_path      = "CCMS_PRD_Allpay/Outbound/"
  ftp_remote_path     = "/Inbound/"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  env                 = local.environment
  secret_name = "LAA-ftp-allpay-inbound-ccms-${local.environment}"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-allpay-inbound-ccms"].arn

}


# #LAA-ftp-allpay-inbound-ccms
module "allpay_ftp_lambda_inbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-allpay-inbound-ccms-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type   = "SFTP_DOWNLOAD"
  ftp_local_path      = "CCMS_PRD_Allpay/Inbound/"
  ftp_remote_path     = "/Outbound/"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                 = local.environment
  secret_name = "LAA-ftp-allpay-inbound-ccms-${local.environment}"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-allpay-inbound-ccms"].arn

}

# #LAA-xerox-outbound-ccms
# module "LAA-ftp-xerox-ccms-outbound" {
#   source              = "./modules/ftp-lambda"
#   lambda_name         = lower(format("LAA-ftp-xerox-ccms-outbound-%s",local.environment))
#   vpc_id              = data.aws_vpc.shared.id
#   subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
#   ftp_transfer_type   = "SFTP_UPLOAD"
#   ftp_local_path      = "CCMS_PRD_DST/Outbound/"
#   ftp_remote_path     = "/Production/outbound/CCMS/"
#   ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
#   env                 = local.environment
#   secret_name = "LAA-ftp-xerox-outbound-${local.environment}"
#   secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-xerox-outbound"].arn
# }

# #LAA-xerox-outbound-ccms-peterborough
# module "LAA-ftp-xerox-ccms-outbound-peterborough" {
#   source              = "./modules/ftp-lambda"
#   lambda_name         = lower(format("LAA-ftp-xerox-ccms-outbound-peterborough-%s",local.environment))
#   vpc_id              = data.aws_vpc.shared.id
#   subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
#   ftp_transfer_type   = "SFTP_UPLOAD"
#   ftp_local_path      = "CCMS_PRD_DST/Outbound/Peterborough/"
#   ftp_remote_path     = "/Production/outbound/PETER/"
#   ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
#   env                 = local.environment
#   secret_name = "LAA-ftp-xerox-outbound-${local.environment}"
#   secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-xerox-outbound"].arn
# }

# #LAA-ftp-eckoh-outbound-ccms
module "LAA-ftp-eckoh-outbound-ccms" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-eckoh-outbound-ccms-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type   = "SFTP_UPLOAD"
  ftp_local_path      = "CCMS_PRD_Eckoh/Outbound/"
  ftp_remote_path     = "/inbound/"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  env                 = local.environment
  secret_name = "LAA-ftp-eckoh-inbound-ccms-${local.environment}"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-eckoh-inbound-ccms"].arn
}


# #LAA-ftp-eckoh-inbound-ccms
module "LAA-ftp-eckoh-inbound-ccms" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-eckoh-inbound-ccms-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type   = "SFTP_DOWNLOAD"
  ftp_local_path      = "CCMS_PRD_Eckoh/Inbound/"
  ftp_remote_path     = "/outbound/"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                 = local.environment
  secret_name = "LAA-ftp-allpay-inbound-ccms-${local.environment}"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-allpay-inbound-ccms"].arn
}

# #LAA-ftp-rossendales-ccms-inbound
module "LAA-ftp-rossendales-ccms-inbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-rossendales-ccms-inbound-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type   = "SFTP_DOWNLOAD"
  ftp_local_path      = "CCMS_PRD_Rossendales/Inbound/"
  ftp_remote_path     = "ccms/OutBound/"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                 = local.environment
  secret_name = "LAA-ftp-rossendales-ccms-inbound-${local.environment}"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-rossendales-ccms-inbound"].arn
}


# #LAA-ftp-1stlocate-ccms-inbound
module "LAA-ftp-1stlocate-ccms-inbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-1stlocate-ccms-inbound-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type   = "SFTP_DOWNLOAD"
  ftp_local_path      = "CCMS_PRD_TDX_DECRYPTED/Inbound/"
  ftp_remote_path     = "/LAA_Direct/ToLAADirect/"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                 = local.environment
  secret_name = "LAA-ftp-1stlocate-ccms-inbound-${local.environment}"
  secret_arn = aws_secretsmanager_secret.secrets["LAA-ftp-1stlocate-ccms-inbound"].arn
}