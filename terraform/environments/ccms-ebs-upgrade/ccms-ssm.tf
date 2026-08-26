resource "aws_ssm_document" "ebs_apps_service_start" {
  name            = "EBS-Apps-Service-Start"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-ebs-apps-service-start.yaml")
}

resource "aws_ssm_document" "ebs_apps_service_status" {
  name            = "EBS-Apps-Service-Status"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-ebs-apps-service-status.yaml")
}

resource "aws_ssm_document" "ebs_apps_service_stop" {
  name            = "EBS-Apps-Service-Stop"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-ebs-apps-service-stop.yaml")
}

resource "aws_ssm_maintenance_window" "ebs_apps_service_status_mw" {
  name                       = "EBS-Apps-Service-Status"
  schedule                   = "cron(*/15 * * * ? *)"
  duration                   = 1
  cutoff                     = 0
  allow_unassociated_targets = false
}

resource "aws_ssm_maintenance_window" "ebs_apps_service_start_mw" {
  name                       = "EBS-Apps-Service-Start"
  schedule                   = "cron(15 7 * * ? *)" # "cron(15 7 ? * MON-FRI *)"
  duration                   = 1
  cutoff                     = 0
  allow_unassociated_targets = false
}

resource "aws_ssm_maintenance_window" "ebs_apps_service_stop_mw" {
  name                       = "EBS-Apps-Service-Stop"
  schedule                   = "cron(45 17 * * ? *)"
  duration                   = 1
  cutoff                     = 0
  allow_unassociated_targets = false
}

# resource "aws_ssm_maintenance_window_target" "ebs_apps_service_status_targets" {
#   window_id        = aws_ssm_maintenance_window.ebs_apps_service_status_mw.id
#   resource_type    = "INSTANCE"
#   
#   targets {
#     key    = "ResourceGroup"
#     values = ["EBS-Apps"]
#   }
# }
# 
# resource "aws_ssm_maintenance_window_target" "ebs_apps_service_start_targets" {
#   window_id        = aws_ssm_maintenance_window.ebs_apps_service_start_mw.id
#   resource_type    = "INSTANCE"
#   
#   targets {
#     key    = "ResourceGroup"
#     values = ["EBS-Apps"]
#   }
# }
# 
# resource "aws_ssm_maintenance_window_target" "ebs_apps_service_stop_targets" {
#   window_id        = aws_ssm_maintenance_window.ebs_apps_service_stop_mw.id
#   resource_type    = "INSTANCE"
#   
#   targets {
#     key    = "ResourceGroup"
#     values = ["EBS-Apps"]
#   }
# }

# resource "aws_ssm_association" "start_app_association" {
#   name            = "StartAppMaintenanceWindowAssociation"
#   document_version = "$LATEST"
#   instance_id     = aws_ssm_maintenance_window_target.foo_ec2_targets.targets[0].key
#   targets {
#     key    = "WindowTargetIds"
#     values = [aws_ssm_maintenance_window_target.foo_ec2_targets.id]
#   }
#   parameters {
#     "documentVersion" = "$LATEST"
#     "documentName"    = aws_ssm_document.start_app_command_document.name
#   }
#   schedule_expression = "cron(15 7 ? * MON-FRI *)"
# }