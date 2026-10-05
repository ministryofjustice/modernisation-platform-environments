resource "aws_athena_database" "alb" {
  name   = "alb_logs"
  bucket = aws_s3_bucket.alb_logs.id

  properties = {
    "classification" = "log"
  }
}