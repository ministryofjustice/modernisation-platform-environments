module "iambackup" {
  source = "./module/lambdapolicy"
    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}
module "lambda_backup" {
  source = "./module/lambda"

backup_policy_name = "${local.application_name}-lambda-instance-policy"
source_file   = local.dbsourcefiles
output_path   = local.zipfiles
filename      = local.zipfiles
function_name = local.functions
handler       = [local.local.dbsnaphandler, local.local.deletesnaphandler, local.local.connecthandler]
role = module.iambackup.backuprole
runtime = [ local.nodejsversion, local.local.pythonversion, local.local.nodejsversion ]




    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}
