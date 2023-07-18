
locals {
  script_idm = <<EOF
#!/bin/bash
. $HOME/.bash_profile
MDOMAIN_HOME=/IDAM/product/runtime/Domain/mserver/IDMDomain
ORACLE_INSTANCE=/IDAM/product/runtime/instances/OID_Instance1
cd $DOMAIN_HOME/servers/AdminServer/logs
FOL=`date +%d%m%y`
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/idm1/$FOL/
  rm $FILE
done
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/idm1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_ods1/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/idm1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_ods1/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/idm1/$FOL/
  rm $FILE
done
cd $ORACLE_INSTANCE/diagnostics/logs/OID/oid1
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/idm1/$FOL/
  rm $FILE
done

EOF

}

resource "aws_ssm_maintenance_window" "idm_window" {
  name     = "idm1-diagnostics-log-archive-poc"
  schedule = "cron(0 0 9 ? * * *)"
  duration = 4
  cutoff   = 1
  schedule_timezone = "Europe/London"
}


resource "aws_ssm_maintenance_window_target" "reg_target_idm" {
  window_id     = aws_ssm_maintenance_window.idm_window.id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.idm_instance_1.id]
  }
}

resource "aws_ssm_maintenance_window_task" "commands_idm" {
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.idm_window.id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.idm_instance_1.id]
  }


  task_invocation_parameters {
    
    run_command_parameters {
      document_version = "$LATEST"

     parameter {
        name = "commands"
        values = [local.script_idm]
      }
    }
    
  }

}