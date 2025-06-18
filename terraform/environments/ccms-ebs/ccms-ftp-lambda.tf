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
    "LAA-ftp-xerox-outbound"
  ]
  base_buckets = ["laa-ccms-inbound", "laa-ccms-outbound", "laa-ccms-ftp-lambda"]

  bucket_names = [
    for name in local.base_buckets : "${name}-${local.environment}-mp"
  ]
}


### secrets for ftp user and password
resource "aws_secretsmanager_secret" "secrets" {
  for_each = toset(local.secret_names)

  name = "${each.value}-${local.environment}"
}

# data "aws_secretsmanager_secret_version" "secrets" {
#   for_each  = toset(local.secret_names)
#   secret_id = "${each.value}-${local.environment}"
# }

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




# locals {
#   secrets_map = {
#     for name in local.secret_names :
#     name => jsondecode(data.aws_secretsmanager_secret_version.secrets[name].secret_string)
#   }

#   # Optionally extract just user/password maps
#   credentials_map = {
#     for name, creds in local.secrets_map :
#     name => {
#       user     = creds.USER
#       password = creds.PASSWORD
#       ssh_key  = creds.SSH_KEY
#     }
#   }
# }


resource "aws_s3_object" "ftp_lambda_layer" {
  bucket = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  key    = "lambda/ftpclientlibs.zip"
  source = "lambda/ftpclientlibs.zip"
}

resource "aws_s3_object" "ftp_client" {
  bucket = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  key    = "lambda/ftp-client.zip"
  source = "lambda/ftp-client.zip"
}

resource "aws_sns_topic" "slack_notifications" {
  name = "ftp-lambda-notifications"
}

module "slack_notification_configuration" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot"

  slack_channel_id = "C08QQNG543F"
  sns_topic_arns   = [aws_sns_topic.slack_notifications.arn]
  tags             = local.tags
  application_name = local.application_name

}


# #LAA-ftp-allpay-inbound-ccms
module "allpay_ftp_lambda_inbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-allpay-inbound-ccms-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id,data.aws_subnet.private_subnets_c.id]
  ftp_host            = "sftp.allpay.cloud"
  ftp_port            = "22"
  ftp_protocol        = "FTPS"
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
  # ftp_user            = local.credentials_map["LAA-ftp-allpay-inbound-ccms"].user
  # ftp_password_path   = local.credentials_map["LAA-ftp-allpay-inbound-ccms"].password
  ftp_user            = ""
  ftp_password_path   = ""
  ftp_file_remove     = "YES"
  ftp_cron            = "cron(0 10 * * ? *)"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  sns_topic_sev5      = ""
  sns_topic_ops       = ""
  # ssh_key_path        = local.credentials_map["LAA-ftp-allpay-inbound-ccms"].ssh_key
  ssh_key_path        = ""
  env                 = local.environment
  s3_bucket_ftp       = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_client= aws_s3_object.ftp_client.key
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key

}


#LAA-xerox-outbound-ccms
module "LAA-ftp-xerox-cis-pay-outbound" {
  source              = "./modules/ftp-lambda"
  lambda_name         = lower(format("LAA-ftp-xerox-cis-pay-outbound-%s",local.environment))
  vpc_id              = data.aws_vpc.shared.id
  subnet_ids          = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id,data.aws_subnet.public_subnets_c.id]
  ftp_host            = "cmseft.services.xerox.com"
  ftp_port            = "22"
  ftp_protocol        = "SFTP"
  ftp_transfer_type   = "SFTP_UPLOAD"
  ftp_file_types      = ""
  ftp_local_path      = "CIS_PAY_DST/Outbound/"
  ftp_remote_path     = "/Test/Outbound/PETER/"
  ftp_require_ssl     = "NO"
  ftp_insecure        = "NO"
  ftp_ca_cert         = ""
  ftp_cert            = ""
  ftp_key             = ""
  ftp_key_type        = ""
  # ftp_user            = local.credentials_map["LAA-ftp-rossendales-ccms-csv-inbound"].user
  # ftp_password_path   = local.credentials_map["LAA-ftp-rossendales-ccms-csv-inbound"].password
  ftp_user            = ""
  ftp_password_path   = ""
  ftp_file_remove     = "YES"
  ftp_cron            = "cron(0 10 * * ? *)"
  ftp_bucket          = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  sns_topic_sev5      = ""
  sns_topic_ops       = ""
  # ssh_key_path        = local.credentials_map["LAA-ftp-rossendales-ccms-csv-inbound"].ssh_key
  ssh_key_path        = ""
  env                 = local.environment
  s3_bucket_ftp       = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_client= aws_s3_object.ftp_client.key
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key

}