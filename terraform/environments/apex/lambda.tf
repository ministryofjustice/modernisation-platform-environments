module "lambda_backup" {
  source = "./module/lambda"

backup_policy_name = "${local.application_name}-lambda-instance-policy"
source_file   = ["dbsnapshot.js","deletesnapshots.py"]
output_path   = ["connectDBFunction.zip","DeleteEBSPendingSnapshots.zip"]
filename      = ["snapshotDBFunction", "deletesnapshotFunction"]
function_name = ["connectDBFunction.zip","DeleteEBSPendingSnapshots.zip"]
handler       = "snapshot/dbsnapshot.handler"

    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}
