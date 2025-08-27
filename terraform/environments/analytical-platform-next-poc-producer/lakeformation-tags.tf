resource "aws_lakeformation_lf_tag" "business_unit" {
  key = "business-unit"
  values = [
    "Central Digital",
    "CICA",
    "HMCTS",
    "HMPPS",
    "HQ",
    "LAA",
    "OPG",
    "Platforms",
    "Technology Services"
  ]
}
