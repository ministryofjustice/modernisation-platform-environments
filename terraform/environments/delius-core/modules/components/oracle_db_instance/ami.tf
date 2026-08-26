# this is generic code to find the latest AMI based on the name regex 
# and owner provided in the variable. 
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

# this is the code to find the pinned AMI if the environment is configured to use pinned AMIs.
# This creates a dependency on the AMI to ensure it is available before the instance is created.
# for stage, preprod and prod envs to avoid conflicts.
data "aws_ami" "oracle_db_pinned" {
  count = var.db_ami.pinned_ami_id != null ? 1 : 0
  filter {
    name   = "image-id"
    values = [var.db_ami.pinned_ami_id]
  }
}

# Local value to create a dependency
locals {
  iam_role_dependency = var.db_ami != "" ? var.db_ami : null

  selected_pinned_ami_name = var.db_ami.pinned_ami_id != null ? data.aws_ami.oracle_db_pinned[0].name : data.aws_ami.oracle_db.name
}
