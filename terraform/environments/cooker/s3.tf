data "aws_s3_bucket" "show_tell_a" {
  bucket = "show-tell-4c1f14-replication-84a84d4e"
}

data "aws_s3_bucket" "show_tell_b" {
  bucket = "show-tell-4c1f14-replication-locked-23476f3f"
}