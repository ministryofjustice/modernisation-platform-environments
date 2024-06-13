data "aws_ami" "oracle_db" {
  owners      = [var.db_ami.owner]
  name_regex  = var.db_ami.name_regex
  most_recent = true
  filter {
    name   = "name"
    values = ["delius_core_ol_8_5_oracle_db_19c_patch*"]
  }

  depends_on = [local.iam_role_dependency]
}

# Local value to create a dependency
locals {
  iam_role_dependency = var.db_ami != "" ? var.db_ami : null
}
