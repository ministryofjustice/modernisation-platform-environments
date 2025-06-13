resource "aws_lakeformation_permissions" "grant_tag_to_consumer" {
  principal   = "arn:aws:iam::593291632749:role/alpha_user_andrewc-moj"
  permissions = ["DESCRIBE", "ASSOCIATE"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = ["prisons"]
  }
}