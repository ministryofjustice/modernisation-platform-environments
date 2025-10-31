
locals {
  script_oam = <<EOF
#!/bin/bash
. $HOME/.bash_profile
cd $DOMAIN_HOME/servers/AdminServer/logs
MDOMAIN_HOME=/IDAM/product/runtime/Domain/mserver/domains/IAMAccessDomain/
FOL=`date +%d%m%y`
find . -name "*.log*" -mtime +30 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam1/$FOL/
  rm $FILE
done
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.log*" -mtime +30 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam1/$FOL/
  rm $FILE
done
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.out*" -mtime +30 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam1/$FOL/
  rm $FILE
done

cd $MDOMAIN_HOME/servers/wls_oam1/logs
find . -name "*.log*" -mtime +30 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_oam1/logs
find . -name "*.out*" -mtime +30 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_ama1/logs
find . -name "*.log*" -mtime +30 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_ama1/logs
find . -name "*.out*" -mtime +30 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam1/$FOL/
  rm $FILE
done

EOF

  script_oam2 = <<EOF
#!/bin/bash
. $HOME/.bash_profile
MDOMAIN_HOME=/IDAM/product/runtime/Domain/mserver/domains/IAMAccessDomain/
DOMAIN_HOME=/IDAM/product/runtime/Domain/aserver/domains/IAMAccessDomain/
FOL=`date +%d%m%y`
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam2/$FOL/
  rm $FILE
done
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam2/$FOL/
  rm $FILE
done

cd $MDOMAIN_HOME/servers/wls_oam2/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_oam2/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_ama2/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_ama2/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oam2/$FOL/
  rm $FILE
done

EOF

}

resource "aws_ssm_maintenance_window" "oam_window" {
  name              = "oam1-${local.application_data.accounts[local.environment].maintenance_window_name}"
  schedule          = "cron(0 0 9 ? * * *)"
  duration          = 4
  cutoff            = 1
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window" "oam2_window" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  name              = "oam2-${local.application_data.accounts[local.environment].maintenance_window_name}"
  schedule          = "cron(0 0 9 ? * * *)"
  duration          = 4
  cutoff            = 1
  schedule_timezone = "Europe/London"
}


resource "aws_ssm_maintenance_window_target" "reg_target_oam" {
  window_id     = aws_ssm_maintenance_window.oam_window.id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oam_instance_1.id]
  }
}

resource "aws_ssm_maintenance_window_target" "reg_target_oam2" {
  count         = contains(["development", "testing"], local.environment) ? 0 : 1
  window_id     = aws_ssm_maintenance_window.oam2_window[0].id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oam_instance_2[0].id]
  }
}
resource "aws_ssm_maintenance_window_task" "commands_oam" {
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.oam_window.id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oam_instance_1.id]
  }


  task_invocation_parameters {

    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "commands"
        values = [local.script_oam]
      }
    }

  }

}

resource "aws_ssm_maintenance_window_task" "commands_oam2" {
  count           = contains(["development", "testing"], local.environment) ? 0 : 1
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.oam2_window[0].id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oam_instance_2[0].id]
  }


  task_invocation_parameters {

    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "commands"
        values = [local.script_oam2]
      }
    }

  }

}