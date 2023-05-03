data "aws_ami" "ec2_laa_oem_development_app" {
  most_recent = true
  executable_users = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "tag:Name"
    values = ["ec2-laa-oem-development-app"]
  }
}

data "aws_ami" "ec2_laa_oem_development_db" {
  most_recent = true
  executable_users = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "tag:Name"
    values = ["ec2-laa-oem-development-db"]
  }
}

data "aws_ebs_snapshot" "oem_app_volume_opt_oem_app" {
  most_recent = true
  restorable_by_user_ids = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "status"
    values = ["completed"]
  }
  filter {
    name   = "tag:Name"
    values = ["laa-oem-app-opt-oem-app"]
  }
}

data "aws_ebs_snapshot" "oem_app_volume_opt_oem_inst" {
  most_recent = true
  restorable_by_user_ids = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "status"
    values = ["completed"]
  }
  filter {
    name   = "tag:Name"
    values = ["laa-oem-app-opt-oem-inst"]
  }
}

data "aws_ebs_snapshot" "oem_db_volume_opt_oem_app" {
  most_recent = true
  restorable_by_user_ids = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "status"
    values = ["completed"]
  }
  filter {
    name   = "tag:Name"
    values = ["laa-oem-db-opt-oem-app"]
  }
}

data "aws_ebs_snapshot" "oem_db_volume_opt_oem_inst" {
  most_recent = true
  restorable_by_user_ids = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "status"
    values = ["completed"]
  }
  filter {
    name   = "tag:Name"
    values = ["laa-oem-db-opt-oem-inst"]
  }
}

data "aws_ebs_snapshot" "oem_db_volume_opt_oem_dbf" {
  most_recent = true
  restorable_by_user_ids = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "status"
    values = ["completed"]
  }
  filter {
    name   = "tag:Name"
    values = ["laa-oem-db-opt-oem-dbf"]
  }
}

data "aws_ebs_snapshot" "oem_db_volume_opt_oem_redo" {
  most_recent = true
  restorable_by_user_ids = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "status"
    values = ["completed"]
  }
  filter {
    name   = "tag:Name"
    values = ["laa-oem-db-opt-oem-redo"]
  }
}

data "aws_ebs_snapshot" "oem_db_volume_opt_oem_arch" {
  most_recent = true
  restorable_by_user_ids = [local.environment_management.account_ids["laa-oem-development"],
    local.environment_management.account_ids["laa-oem-test"],
    local.environment_management.account_ids["laa-oem-preproduction"],
    local.environment_management.account_ids["laa-oem-production"]
  ]
  filter {
    name   = "status"
    values = ["completed"]
  }
  filter {
    name   = "tag:Name"
    values = ["laa-oem-db-opt-oem-arch"]
  }
}
