resource "aws_lakeformation_lf_tag" "project" {
  /* 
    This is a special tag that is populated by the service layer (boto: LakeFormation.Client.update_lf_tag)
    "data-platform" is a placeholder value as values cannot be an empty list
    Of note: "Add or remove up to 1000 values; each value must be less than 50 characters"
  */
  key    = "project"
  values = ["data-platform"]
  lifecycle {
    ignore_changes = [values]
  }
}

# resource "aws_lakeformation_lf_tag" "domain" {
#   key = "domain"
#   values = [
#     "electronic-monitoring",
#     "prisons",
#     "probation"
#   ]
# }

# resource "aws_lakeformation_lf_tag" "sensitivity" {
#   key = "sensitivity"
#   values = [
#     "non_sensitive",
#     "sensitive",
#   ]
# }
