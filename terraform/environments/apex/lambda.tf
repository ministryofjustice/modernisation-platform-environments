module "iambackup" {
  source = "./module/lambdapolicy"
    backup_policy_name = "laa-${local.application_name}-${local.environment}-policy"
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
handler       = local.handlers
role = module.iambackup.backuprole
runtime = local.runtime




    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}


resource "aws_cloudwatch_event_rule" "mon_sun" {
    name = "${local.application_name}-createSnapshotRule-LWN8E1LNHFJR"
    description = "Fires every five minutes"
    schedule_expression = "0 2 ? * MON-SUN *"
}

resource "aws_cloudwatch_event_target" "check_mon_sun" {
    rule = aws_cloudwatch_event_rule.mon_sun.name
    arn = module.lambda_backup.lambda_function
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_mon_sun" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = module.lambda_backup.lambda_function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.mon_sun.arn
}