resource "aws_lakeformation_lf_tag" "domain" {
  key = "domain"
  values = [
    "electronic-monitoring",
    "prisons",
    "probation",
  ]
}

resource "aws_lakeformation_lf_tag" "sensitivity" {
  key = "sensitivity"
  values = [
    "sensitive",
    "non-sensitive",
    "contains-pii",
  ]
}
