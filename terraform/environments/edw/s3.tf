##################################
### S3 for Provisioning Scripts
##################################

resource "aws_s3_bucket" "scripts" {
  bucket = "${local.application_name}-${local.environment}-scripts"
  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-scripts" }
  )
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.scripts
  ]
}

resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

####### Upload scripts to S3 #######

resource "aws_s3_object" "disk_space_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "disk_space_alert.sh"
  source      = "./scripts/disk_space_alert.sh"
  source_hash = filemd5("./scripts/disk_space_alert.sh")
}

resource "aws_s3_object" "free_space_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "freespace_alert.sh"
  source      = "./scripts/freespace_alert.sh"
  source_hash = filemd5("./scripts/freespace_alert.sh")
}

resource "aws_s3_object" "free_space_sql_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "freespace_alert.sql"
  source      = "./scripts/freespace_alert.sql"
  source_hash = filemd5("./scripts/freespace_alert.sql")
}

resource "aws_s3_object" "maat_sh_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "maat_05365_ware_db_changes.sh"
  source      = "./scripts/maat_05365_ware_db_changes.sh"
  source_hash = filemd5("./scripts/maat_05365_ware_db_changes.sh")
}

resource "aws_s3_object" "maat_sql_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "maat_05365_ware_db_changes.sql"
  source      = "./scripts/maat_05365_ware_db_changes.sql"
  source_hash = filemd5("./scripts/maat_05365_ware_db_changes.sql")
}

resource "aws_s3_object" "pmon_check_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "pmon_check.sh"
  source      = "./scripts/pmon_check.sh"
  source_hash = filemd5("./scripts/pmon_check.sh")
}

resource "aws_s3_object" "rootrotate_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "rootrotate.sh"
  source      = "./scripts/rootrotate.sh"
  source_hash = filemd5("./scripts/rootrotate.sh")
}

resource "aws_s3_object" "alert_rota_script" {
  bucket      = aws_s3_bucket.scripts.id
  key         = "alert_rota.sh"
  source      = "./scripts/alert_rota.sh"
  source_hash = filemd5("./scripts/alert_rota.sh")
}

