
locals {
  script = <<EOF
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
  aws s3 cp $FILE s3://laa-portal-development-archive-mp/ohs1/$FOL/
  rm $FILE
done

EOF

}

resource "aws_ssm_maintenance_window" "window" {
  name     = "ohs1-diagnostics-log-archive-poc"
  schedule = "cron(0 0 9 ? * * *)"
  duration = 4
  cutoff   = 1
  schedule_timezone = "Europe/London"
}


resource "aws_ssm_maintenance_window_target" "reg_target" {
  window_id     = aws_ssm_maintenance_window.window.id 
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ohs_instance_1.id]
  }
}

resource "aws_ssm_maintenance_window_task" "commands" {
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.window.id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ohs_instance_1.id]
  }


  task_invocation_parameters {
    
    run_command_parameters {
      document_version = "$LATEST"

     parameter {
        name = "commands"
        values = [local.script]
      }
    }
    
  }

}