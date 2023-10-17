module "lambda_backup" {
  source = "./module/lambda"

backup_policy_name = "${local.application_name}-lambda-instance-policy"
source_file   = var.source_file[count.index]
output_path   = var.output_path[count.index]
filename      = var.filename[count.index]
function_name = var.function_name[count.index]
handler       = "snapshot/dbsnapshot.handler"

    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}
