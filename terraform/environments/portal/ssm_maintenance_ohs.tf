
locals {
  script_ohs = <<EOF
#!/bin/bash
. $HOME/.bash_profile
FOL=`date +%d%m%y`
LHOME=/IDAM/product/runtime/Domain/mserver/instances/ohs1/diagnostics/logs/OHS/ohs1
MDOMAIN_HOME=/IDAM/product/runtime/Domain/mserver/domains/IAMGovernanceDomain
cd $LHOME
#find . -name "AdminServer.log*" -mtime +30 -exec ls -lt {} \;
#find . -name "AdminServer.log*" -mtime +30 -exec rm -f {} \;
#find . -name "AdminServer.log*" -mtime +30 -exec ls -1t {} \; |aws s3 cp AdminServer.log00001 s3://laa-portal-development-archive/
#find . -name "AdminServer.log*" -o -name "IAMAccessDomain.log*" -mtime +30 -exec ls -1t {} \; |while read FILE
#find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
find . -type f \( -name "*.log" -o -name "*_log*" -o -name "oblog.log.*" \) -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE  ${local.application_data.accounts[local.environment].url}/ohs1/$FOL/
  rm $FILE
done

EOF

  script_ohs2 = <<EOF
#!/bin/bash
. $HOME/.bash_profile
FOL=`date +%d%m%y`
LHOME=/IDAM/product/runtime/Domain/mserver/instances/ohs2/diagnostics/logs/OHS/ohs2
MDOMAIN_HOME=/IDAM/product/runtime/Domain/mserver/domains/IAMGovernanceDomain
cd $LHOME
find . -type f \( -name "*.log*" -o -name "*_log*" -o -name "oblog.log.*" \) -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/ohs2/$FOL/
  rm $FILE
done

EOF

}

resource "aws_ssm_maintenance_window" "ohs_window" {
  name              = "ohs1-${local.application_data.accounts[local.environment].maintenance_window_name}"
  schedule          = "cron(0 0 9 ? * * *)"
  duration          = 4
  cutoff            = 1
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window" "ohs2_window" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  name              = "ohs2-${local.application_data.accounts[local.environment].maintenance_window_name}"
  schedule          = "cron(0 0 9 ? * * *)"
  duration          = 4
  cutoff            = 1
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window_target" "reg_target_ohs" {
  window_id     = aws_ssm_maintenance_window.ohs_window.id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ohs_instance_1.id]
  }
}

resource "aws_ssm_maintenance_window_target" "reg_target_ohs2" {
  count         = contains(["development", "testing"], local.environment) ? 0 : 1
  window_id     = aws_ssm_maintenance_window.ohs2_window[0].id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ohs_instance_2[0].id]
  }
}

resource "aws_ssm_maintenance_window_task" "commands_ohs" {
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.ohs_window.id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ohs_instance_1.id]
  }


  task_invocation_parameters {

    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "commands"
        values = [local.script_ohs]
      }
    }

  }

}

resource "aws_ssm_maintenance_window_task" "commands_ohs2" {
  count           = contains(["development", "testing"], local.environment) ? 0 : 1
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.ohs2_window[0].id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ohs_instance_2[0].id]
  }


  task_invocation_parameters {

    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "commands"
        values = [local.script_ohs2]
      }
    }

  }

}