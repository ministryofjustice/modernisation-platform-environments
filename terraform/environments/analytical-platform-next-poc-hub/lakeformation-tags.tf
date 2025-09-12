module "lakeformation_tags" {
  source = "../../modules/analytical-platform-next/lakeformation/tag-ontology"
}

# resource "aws_lakeformation_resource_lf_tags" "wildcard_db_tags" {
#   database {
#     name = "720819236209_wildcard_db"
#   }

#   lf_tag {
#     key   = "domain"
#     value = "electronic-monitoring"
#   }

#   lf_tag {
#     key   = "sensitivity"
#     value = "non-sensitive"
#   }
# }

# resource "aws_lakeformation_resource_lf_tags" "individual_db_tags" {
#   database {
#     name = "720819236209_individual_db"
#   }

#   lf_tag {
#     key   = "domain"
#     value = "electronic-monitoring"
#   }

#   lf_tag {
#     key   = "sensitivity"
#     value = "sensitive"
#   }
# }
