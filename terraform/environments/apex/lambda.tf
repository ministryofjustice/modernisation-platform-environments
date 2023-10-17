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
source_file   = ["dbsnapshot.js","deletesnapshots.py","dbconnect.js"]
output_path   = ["snapshotDBFunction.zip","deletesnapshotFunction.zip","connectDBFunction.zip”"]
filename      = ["snapshotDBFunction.zip", "deletesnapshotFunction.zip","connectDBFunction.zip"]
function_name = ["snapshotDBFunction","deletesnapshotFunction", "connectDBFunction"]
handler       = ["snapshot/dbsnapshot.handler","deletesnapshots.lambda_handler","ssh/dbconnect.handler"]
role = module.iambackup.backuprole
runtime = [ "nodejs18.x","python3.8","nodejs18.x"]




    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}
