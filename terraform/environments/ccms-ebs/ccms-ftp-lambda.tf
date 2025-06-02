
### secrets for ftp user and password
resource "aws_secretsmanager_secret" "ftp_credentials" {
  name        = lower(format("laa-ccms-ebs-ftp-credentials-%s",local.environment))
  description = "A secret for storing ftp credentials"
}


#### bucket for laa-ccms-inbound for storing files from lambda
resource "aws_s3_bucket" "inbound_bucket" {
  bucket = lower(format("laa-ccms-inbound-%s-mp",local.environment))  # ccms inbound bucket

}


resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_encryption" {
  bucket = aws_s3_bucket.inbound_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

##### bucket for storing lambda layers and ftp client code
resource "aws_s3_bucket" "ftp_bucket" {
  bucket = lower(format("laa-ccms-ftp-lambda-%s-mp",local.environment))  # ccms lambda bucket

}
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_encryption_ftp_lambda" {
  bucket = aws_s3_bucket.ftp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_object" "ftp_lambda_layer" {
  bucket = aws_s3_bucket.ftp_bucket.bucket
  key    = "lambda/ftpclientlibs.zip"
  source = "lambda/ftpclientlibs.zip"
}

resource "aws_s3_object" "ftp_client" {
  bucket = aws_s3_bucket.ftp_bucket.bucket
  key    = "lambda/ftp-client.zip"
  source = "lambda/ftp-client.zip"
}


#LAA-ftp-allpay-inbound-ccms
module "ftp_lambda" {
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
  ftp_user            = ""
  ftp_password_path   = "/secure/path"
  ftp_file_remove     = "YES"
  ftp_cron            = "cron(0 10 * * ? *)"
  ftp_bucket          = aws_s3_bucket.inbound_bucket.id
  sns_topic_sev5      = ""
  sns_topic_ops       = ""
  ssh_key_path        = ""
  env                 = local.environment
  s3_bucket_ftp       = aws_s3_bucket.ftp_bucket.bucket
  s3_object_ftp_client= aws_s3_object.ftp_client.key
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key

}
