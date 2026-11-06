data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


data "aws_ssm_parameter" "weblogic_task_count" {
  name = "/delius-core-${var.env_name}/weblogic/task_count"
}

data "aws_ssm_parameter" "weblogic_eis_task_count" {
  name = "/delius-core-${var.env_name}/weblogic-eis/task_count"
}

data "aws_ssm_parameter" "weblogic_data_task_count" {
  count = var.env_name == "test" ? 1 : 0
  name  = "/delius-core-${var.env_name}/weblogic-data/task_count"
}